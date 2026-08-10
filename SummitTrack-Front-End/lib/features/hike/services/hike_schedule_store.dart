import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/services/hike_notification_service.dart';
import '../models/scheduled_hike.dart';
import '../utils/mountain_schedule_identity.dart';

class HikeScheduleException implements Exception {
  const HikeScheduleException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HikeScheduleStore extends ChangeNotifier {
  HikeScheduleStore._({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static final HikeScheduleStore instance = HikeScheduleStore._();
  static const _storageKeyPrefix = 'summittrack_scheduled_hikes_v1_';
  static const _userDocumentScheduleField = 'scheduledHikesById';
  static const _permissionMessage =
      'You do not have permission to access this scheduled hike.';

  @visibleForTesting
  static String scheduleDocumentPathForTesting({
    required String userId,
    required String hikeId,
  }) {
    return 'users/$userId/scheduled_hikes/$hikeId';
  }

  @visibleForTesting
  static ScheduledHike? activeHikeForTrailTodayForTesting({
    required Iterable<ScheduledHike> scheduledHikes,
    required String? activeUserId,
    required String mountainId,
    required String trailId,
    required DateTime today,
    String? trailName,
  }) {
    return _activeHikeForTrailToday(
      scheduledHikes: scheduledHikes,
      activeUserId: activeUserId,
      mountainId: mountainId,
      trailId: trailId,
      today: today,
      trailName: trailName,
    );
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final List<ScheduledHike> _scheduledHikes = <ScheduledHike>[];

  StreamSubscription<User?>? _authSubscription;
  Future<void>? _loadFuture;
  String? _activeUserId;
  Object? _loadError;
  bool _isStarted = false;
  bool _isLoaded = false;
  bool _isLoading = false;
  int _loadGeneration = 0;

  bool get isLoaded => _isLoaded;

  bool get isLoading => _isLoading;

  Object? get loadError => _loadError;

  String? get activeUserId => _activeUserId;

  List<ScheduledHike> get scheduledHikes {
    return List<ScheduledHike>.unmodifiable(_sorted(_scheduledHikes));
  }

  /// Getter para makuha ang lahat ng nakaplanong hike para sa araw na ito.
  List<ScheduledHike> get todayHikes {
    return _scheduledHikes.where((hike) => hike.isHikeToday).toList();
  }

  /// Kukunin ang scheduled hike sa specific na bundok kung ARAW NG HIKE ngayon.
  ScheduledHike? activeHikeForMountainToday(String mountainId) {
    final normalizedMountainId = _normalizeMountainId(mountainId);
    final matches = _scheduledHikes.where((hike) {
      return _mountainMatches(hike, normalizedMountainId) &&
          _belongsToActiveUser(hike) &&
          hike.isActive &&
          hike.isHikeToday;
    });
    return matches.isEmpty ? null : matches.first;
  }

  ScheduledHike? activeHikeForTrailToday(
    String mountainId,
    String trailId, {
    DateTime? today,
    String? trailName,
  }) {
    return _activeHikeForTrailToday(
      scheduledHikes: _scheduledHikes,
      activeUserId: _activeUserId,
      mountainId: mountainId,
      trailId: trailId,
      today: today ?? DateTime.now(),
      trailName: trailName,
    );
  }

  static ScheduledHike? _activeHikeForTrailToday({
    required Iterable<ScheduledHike> scheduledHikes,
    required String? activeUserId,
    required String mountainId,
    required String trailId,
    required DateTime today,
    String? trailName,
  }) {
    final normalizedMountainId = _normalizeMountainId(mountainId);
    final currentTrailKeys = _trailIdentityKeys(
      trailId: trailId,
      trailName: trailName,
      mountainId: normalizedMountainId,
    );
    final todayKey = ScheduledHike.dateKey(today);

    for (final hike in _sorted(scheduledHikes)) {
      final scheduledTrailKeys = _trailIdentityKeys(
        trailId: hike.trailId,
        trailName: hike.trailName,
        mountainId: normalizedMountainId,
      );
      final scheduledDateKey = ScheduledHike.dateKey(hike.hikeDate);
      final userMatch = _belongsToUser(hike, activeUserId);
      final statusMatch = hike.isActive;
      final mountainMatch = _mountainMatches(hike, normalizedMountainId);
      final trailMatch = currentTrailKeys
          .intersection(scheduledTrailKeys)
          .isNotEmpty;
      final dateMatch = scheduledDateKey == todayKey;
      final eligible =
          userMatch && statusMatch && mountainMatch && trailMatch && dateMatch;

      _logStartNavigationEligibility(
        currentMountainId: normalizedMountainId,
        currentTrailId: trailId,
        currentTrailKeys: currentTrailKeys,
        scheduledHike: hike,
        scheduledTrailKeys: scheduledTrailKeys,
        scheduledDateKey: scheduledDateKey,
        todayKey: todayKey,
        userMatch: userMatch,
        mountainMatch: mountainMatch,
        trailMatch: trailMatch,
        dateMatch: dateMatch,
        statusMatch: statusMatch,
        eligible: eligible,
      );

      if (eligible) {
        return hike;
      }
    }

    if (scheduledHikes.isEmpty) {
      _logStartNavigationNoSchedules(
        currentMountainId: normalizedMountainId,
        currentTrailId: trailId,
        todayKey: todayKey,
      );
    }

    return null;
  }

  void start() {
    if (_isStarted) {
      return;
    }

    _isStarted = true;
    _authSubscription = _auth.authStateChanges().listen((user) {
      unawaited(_handleAuthChanged(user));
    });
    unawaited(_handleAuthChanged(_auth.currentUser));
  }

  Future<void> load() {
    start();

    final user = _auth.currentUser;
    if (user == null) {
      _handleSignedOut();
      return SynchronousFuture<void>(null);
    }

    if (_activeUserId == user.uid && (_isLoaded || _isLoading)) {
      return _loadFuture ?? SynchronousFuture<void>(null);
    }

    return _loadForUser(user);
  }

  Future<HikeReminderResult?> saveScheduledHike(ScheduledHike hike) async {
    _validateSchedulableDate(hike.hikeDate);
    start();

    final user = _auth.currentUser;
    if (user == null) {
      throw const HikeScheduleException(
        'Please sign in first before scheduling a hike.',
      );
    }

    _logSchedule('Confirm tapped');
    _logSchedule(
      'Selected mountain: ${hike.mountainName} (${hike.mountainId})',
    );
    _logSchedule('Selected trail: ${hike.trailName} (${hike.trailId})');
    _logSchedule('Selected date: ${ScheduledHike.dateKey(hike.hikeDate)}');
    _logAccess('scheduled_hike_access_started', {
      'operation': 'save',
      'queryType': 'user_subcollection_document',
    });
    _logAuthenticatedUser(user);
    _logAccess('requested_hike_id', {'hikeId': hike.id});

    await _waitForCurrentUserLoad(user);

    final ownedHike = hike.copyWith(
      ownerUid: user.uid,
      updatedAt: DateTime.now(),
    );

    try {
      _logSchedule('Starting save');
      await _saveToAccountStorage(user, ownedHike, includeCreatedAt: true);
      _logSchedule('Save success');
    } catch (error) {
      _logSchedule('Save failure: ${_errorSummary(error)}');
      throw HikeScheduleException(
        _firebaseMessage(
          error,
          fallback: 'Unable to save hike date. Please try again.',
        ),
      );
    }

    _activeUserId = user.uid;
    _upsertSchedule(ownedHike);
    _isLoaded = true;
    _isLoading = false;
    _loadError = null;
    await _persistUserCache(user.uid);
    notifyListeners();
    final notificationResult = await HikeNotificationService.instance
        .handleSavedHike(ownedHike);
    _logSchedule(
      'Notification result: ${notificationResult.status.name} '
      '(pendingConfirmed=${notificationResult.pendingScheduleConfirmed}, '
      'cloudConfirmed=${notificationResult.cloudConfirmationWritten})',
    );
    return notificationResult;
  }

  Future<HikeReminderResult?> updateScheduledHike({
    required ScheduledHike oldHike,
    required ScheduledHike updatedHike,
  }) async {
    _validateSchedulableDate(updatedHike.hikeDate);
    start();

    final user = _auth.currentUser;
    if (user == null) {
      throw const HikeScheduleException(
        'Please sign in first before updating a scheduled hike.',
      );
    }

    await _waitForCurrentUserLoad(user);

    final ownedUpdatedHike = updatedHike.copyWith(
      ownerUid: user.uid,
      updatedAt: DateTime.now(),
    );
    final ownedOldHike = oldHike.copyWith(ownerUid: user.uid);

    try {
      await _saveToAccountStorage(
        user,
        ownedUpdatedHike,
        includeCreatedAt: oldHike.id != updatedHike.id,
      );
      if (oldHike.id != updatedHike.id) {
        await _deleteFromAccountStorage(user, oldHike.id);
      }
    } catch (error) {
      throw HikeScheduleException(
        _firebaseMessage(
          error,
          fallback: 'Unable to update hike date. Please try again.',
        ),
      );
    }

    _activeUserId = user.uid;
    _scheduledHikes.removeWhere((hike) => hike.id == oldHike.id);
    _upsertSchedule(ownedUpdatedHike);
    _isLoaded = true;
    _isLoading = false;
    _loadError = null;
    await _persistUserCache(user.uid);
    notifyListeners();
    final notificationResult = await HikeNotificationService.instance
        .handleUpdatedHike(
          oldHike: ownedOldHike,
          updatedHike: ownedUpdatedHike,
        );
    _logSchedule(
      'Notification update result: ${notificationResult.status.name} '
      '(pendingConfirmed=${notificationResult.pendingScheduleConfirmed}, '
      'cloudConfirmed=${notificationResult.cloudConfirmationWritten})',
    );
    return notificationResult;
  }

  Future<void> deleteScheduledHike(String hikeId) async {
    start();

    final user = _auth.currentUser;
    if (user == null) {
      throw const HikeScheduleException(
        'Please sign in first before deleting a scheduled hike.',
      );
    }

    await _waitForCurrentUserLoad(user);

    try {
      await _deleteFromAccountStorage(user, hikeId);
    } catch (error) {
      throw HikeScheduleException(
        _firebaseMessage(
          error,
          fallback: 'Unable to delete that scheduled hike. Please try again.',
        ),
      );
    }

    _activeUserId = user.uid;
    _scheduledHikes.removeWhere((hike) => hike.id == hikeId);
    _isLoaded = true;
    _isLoading = false;
    _loadError = null;
    await _persistUserCache(user.uid);
    notifyListeners();
    await HikeNotificationService.instance.handleDeletedHike(
      uid: user.uid,
      hikeId: hikeId,
    );
  }

  List<ScheduledHike> upcomingForMountain(
    String mountainId, {
    DateTime? today,
  }) {
    final normalizedToday = ScheduledHike.dateOnly(today ?? DateTime.now());
    final normalizedMountainId = _normalizeMountainId(mountainId);

    return _sorted(
      _scheduledHikes.where((hike) {
        return _mountainMatches(hike, normalizedMountainId) &&
            hike.isUpcomingFrom(normalizedToday);
      }),
    );
  }

  ScheduledHike? nextUpcomingForMountain(String mountainId, {DateTime? today}) {
    final hikes = upcomingForMountain(mountainId, today: today);
    return hikes.isEmpty ? null : hikes.first;
  }

  Map<String, List<ScheduledHike>> upcomingByMountain({DateTime? today}) {
    final normalizedToday = ScheduledHike.dateOnly(today ?? DateTime.now());
    final grouped = <String, List<ScheduledHike>>{};

    for (final hike in _scheduledHikes) {
      if (!hike.isUpcomingFrom(normalizedToday)) {
        continue;
      }

      grouped.putIfAbsent(hike.mountainId, () => <ScheduledHike>[]).add(hike);
    }

    for (final hikes in grouped.values) {
      hikes.sort(_compareByDate);
    }

    return grouped;
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  Future<void> _handleAuthChanged(User? user) {
    if (user == null) {
      _handleSignedOut();
      return SynchronousFuture<void>(null);
    }

    if (_activeUserId == user.uid && (_isLoaded || _isLoading)) {
      return _loadFuture ?? SynchronousFuture<void>(null);
    }

    return _loadForUser(user);
  }

  void _handleSignedOut() {
    final shouldNotify =
        _activeUserId != null ||
        _scheduledHikes.isNotEmpty ||
        _isLoaded ||
        _isLoading ||
        _loadError != null;

    _loadGeneration++;
    _activeUserId = null;
    _loadFuture = null;
    _loadError = null;
    _isLoaded = false;
    _isLoading = false;
    _scheduledHikes.clear();

    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> _waitForCurrentUserLoad(User user) async {
    if (_activeUserId == user.uid && _loadFuture != null) {
      await _loadFuture;
      return;
    }

    if (_activeUserId == user.uid && _isLoaded) {
      return;
    }

    await _loadForUser(user);
  }

  Future<void> _loadForUser(User user) {
    final generation = ++_loadGeneration;

    _activeUserId = user.uid;
    _isLoading = true;
    _isLoaded = false;
    _loadError = null;
    _scheduledHikes.clear();
    notifyListeners();

    _loadFuture = _loadFromAccountStorage(user, generation).whenComplete(() {
      if (_activeUserId == user.uid && generation == _loadGeneration) {
        _loadFuture = null;
      }
    });

    return _loadFuture!;
  }

  Future<void> _loadFromAccountStorage(User user, int generation) async {
    final cachedHikes = await _loadUserCache(user.uid);
    if (!_isCurrentLoad(user.uid, generation)) {
      return;
    }

    if (cachedHikes.isNotEmpty) {
      _replaceSchedules(cachedHikes);
      notifyListeners();
    }

    try {
      _logFetch('Fetch started');
      _logFetch('Current user UID: ${_safeIdentifier(user.uid)}');
      final cloudHikes = await _loadCloudSchedules(user);
      if (!_isCurrentLoad(user.uid, generation)) {
        return;
      }

      _replaceSchedules(cloudHikes);
      _isLoaded = true;
      _isLoading = false;
      _loadError = null;
      await _persistUserCache(user.uid);
      _logFetch('Response status: success');
      _logFetch('Loaded schedules count: ${cloudHikes.length}');
      notifyListeners();
    } catch (error) {
      if (!_isCurrentLoad(user.uid, generation)) {
        return;
      }

      _isLoaded = cachedHikes.isNotEmpty;
      _isLoading = false;
      _loadError = error;
      _logFetch('Response status: failure');
      _logFetch('Permission failure source: ${_errorSummary(error)}');
      notifyListeners();
    }
  }

  Future<List<ScheduledHike>> _loadCloudSchedules(User user) async {
    try {
      final primaryHikes = await _loadPrimaryCollectionSchedules(user);
      final userDocumentHikes = await _loadUserDocumentSchedules(
        user,
        requiredFallback: false,
      );

      return _dedupeById(<ScheduledHike>[
        ...userDocumentHikes,
        ...primaryHikes,
      ]);
    } on FirebaseException catch (error) {
      if (!_isPermissionDenied(error)) {
        rethrow;
      }

      _logFetch(
        'Permission failure source: primary scheduled_hikes read denied',
      );
      _logFetch(
        'Query path: ${_safePath(_userDocumentSchedulePath(user.uid))}',
      );

      return _loadUserDocumentSchedules(user, requiredFallback: true);
    }
  }

  Future<List<ScheduledHike>> _loadPrimaryCollectionSchedules(User user) async {
    final queryPath = _scheduleCollectionPath(user.uid);
    _logFetch('Query path: ${_safePath(queryPath)}');
    _logAccess('scheduled_hike_access_started', {
      'operation': 'query',
      'queryType': 'user_subcollection',
      'requested_firestore_path': _safePath(queryPath),
    });
    _logAuthenticatedUser(user);
    _logAccess('scheduled_hike_query_started', {
      'operation': 'get',
      'requested_firestore_path': _safePath(queryPath),
    });

    try {
      final snapshot = await _scheduleCollection(user.uid).get();
      _logAccess('scheduled_hike_query_completed', {
        'operation': 'get',
        'documentCount': snapshot.docs.length,
        'requested_firestore_path': _safePath(queryPath),
      });
      return snapshot.docs
          .map(
            (doc) => ScheduledHike.fromFirestore(
              documentId: doc.id,
              data: doc.data(),
              ownerUid: user.uid,
            ),
          )
          .where((hike) => hike.ownerUid == null || hike.ownerUid == user.uid)
          .toList();
    } catch (error, stackTrace) {
      _logAccessFailure(
        event: 'scheduled_hike_query_failed',
        operation: 'get',
        firestorePath: queryPath,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ScheduledHike>> _loadUserDocumentSchedules(
    User user, {
    required bool requiredFallback,
  }) async {
    try {
      final snapshot = await _userDocument(user.uid).get();
      final data = snapshot.data();
      final rawSchedules =
          data?[_userDocumentScheduleField] ?? data?['scheduledHikes'];
      final hikes = _decodeUserDocumentHikes(rawSchedules, ownerUid: user.uid);

      if (hikes.isNotEmpty || requiredFallback) {
        _logFetch('Response status: user document fallback success');
        _logFetch('Loaded fallback schedules count: ${hikes.length}');
      }

      return hikes;
    } catch (error) {
      if (requiredFallback) {
        rethrow;
      }

      _logFetch(
        'Optional user document schedule read failed: ${_errorSummary(error)}',
      );
      return const <ScheduledHike>[];
    }
  }

  List<ScheduledHike> _decodeUserDocumentHikes(
    Object? rawSchedules, {
    required String ownerUid,
  }) {
    if (rawSchedules == null) {
      return const <ScheduledHike>[];
    }

    final hikes = <ScheduledHike>[];

    if (rawSchedules is Map) {
      for (final entry in rawSchedules.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          hikes.add(
            ScheduledHike.fromFirestore(
              documentId: entry.key.toString(),
              data: value,
              ownerUid: ownerUid,
            ),
          );
        } else if (value is Map) {
          hikes.add(
            ScheduledHike.fromFirestore(
              documentId: entry.key.toString(),
              data: Map<String, dynamic>.from(value),
              ownerUid: ownerUid,
            ),
          );
        }
      }
    } else if (rawSchedules is List) {
      for (final value in rawSchedules) {
        if (value is Map<String, dynamic>) {
          hikes.add(
            ScheduledHike.fromFirestore(
              documentId: _readDocumentId(value),
              data: value,
              ownerUid: ownerUid,
            ),
          );
        } else if (value is Map) {
          final data = Map<String, dynamic>.from(value);
          hikes.add(
            ScheduledHike.fromFirestore(
              documentId: _readDocumentId(data),
              data: data,
              ownerUid: ownerUid,
            ),
          );
        }
      }
    }

    return _dedupeById(
      hikes.where((hike) => hike.ownerUid == null || hike.ownerUid == ownerUid),
    );
  }

  Future<void> _saveToAccountStorage(
    User user,
    ScheduledHike ownedHike, {
    required bool includeCreatedAt,
  }) async {
    await _saveToPrimaryCollection(
      user,
      ownedHike,
      includeCreatedAt: includeCreatedAt,
    );
  }

  Future<void> _saveToPrimaryCollection(
    User user,
    ScheduledHike ownedHike, {
    required bool includeCreatedAt,
  }) async {
    final documentPath = _scheduleDocumentPath(user.uid, ownedHike.id);
    final documentReference = _scheduleCollection(user.uid).doc(ownedHike.id);
    _logSchedule('Storage path/endpoint: ${_safePath(documentPath)}');
    _logAccess('requested_firestore_path', {
      'operation': 'set',
      'requested_firestore_path': _safePath(documentPath),
    });
    _logAccess('requested_hike_id', {'hikeId': ownedHike.id});
    _logAccess('scheduled_hike_query_started', {
      'operation': 'transaction_get',
      'requested_firestore_path': _safePath(documentPath),
    });

    try {
      await _firestore.runTransaction((transaction) async {
        final existingSnapshot = await transaction.get(documentReference);
        final shouldIncludeCreatedAt =
            includeCreatedAt && !existingSnapshot.exists;
        _logAccess('scheduled_hike_query_completed', {
          'operation': 'transaction_get',
          'documentExists': existingSnapshot.exists,
          'includeCreatedAt': shouldIncludeCreatedAt,
          'requested_firestore_path': _safePath(documentPath),
        });

        transaction.set(
          documentReference,
          ownedHike.toFirestore(
            ownerUid: user.uid,
            includeCreatedAt: shouldIncludeCreatedAt,
          ),
          SetOptions(merge: true),
        );
      });
    } catch (error, stackTrace) {
      _logAccessFailure(
        event: 'scheduled_hike_query_failed',
        operation: 'transaction_get_or_set',
        firestorePath: documentPath,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    _logSchedule('Save response status: primary success');
  }

  Future<void> _deleteFromAccountStorage(User user, String hikeId) async {
    await _scheduleCollection(user.uid).doc(hikeId).delete();

    try {
      await _deleteFromUserDocumentFallback(user, hikeId);
    } catch (error) {
      _logSchedule(
        'Optional user document fallback delete failed: ${_errorSummary(error)}',
      );
    }
  }

  Future<void> _deleteFromUserDocumentFallback(User user, String hikeId) async {
    try {
      await _userDocument(
        user.uid,
      ).update({'$_userDocumentScheduleField.$hikeId': FieldValue.delete()});
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') {
        return;
      }

      rethrow;
    }
  }

  bool _isCurrentLoad(String userId, int generation) {
    return _activeUserId == userId && generation == _loadGeneration;
  }

  Future<List<ScheduledHike>> _loadUserCache(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final rawJson = preferences.getString(_storageKeyForUser(userId));
    return _decodeHikes(rawJson, ownerUid: userId);
  }

  Future<void> _persistUserCache(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _sorted(_scheduledHikes).map((hike) => hike.toJson()).toList(),
    );

    await preferences.setString(_storageKeyForUser(userId), encoded);
  }

  List<ScheduledHike> _decodeHikes(
    String? rawJson, {
    required String ownerUid,
  }) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return <ScheduledHike>[];
    }

    final loadedHikes = <ScheduledHike>[];

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            loadedHikes.add(
              ScheduledHike.fromJson(item).copyWith(ownerUid: ownerUid),
            );
          } else if (item is Map) {
            loadedHikes.add(
              ScheduledHike.fromJson(
                Map<String, dynamic>.from(item),
              ).copyWith(ownerUid: ownerUid),
            );
          }
        }
      }
    } catch (_) {
      return <ScheduledHike>[];
    }

    return _dedupeById(loadedHikes);
  }

  void _replaceSchedules(Iterable<ScheduledHike> hikes) {
    _scheduledHikes
      ..clear()
      ..addAll(_dedupeById(hikes));
  }

  void _upsertSchedule(ScheduledHike hike) {
    final existingIndex = _scheduledHikes.indexWhere(
      (scheduledHike) => scheduledHike.id == hike.id,
    );

    if (existingIndex == -1) {
      _scheduledHikes.add(hike);
    } else {
      _scheduledHikes[existingIndex] = hike;
    }

    _scheduledHikes
      ..sort(_compareByDate)
      ..sort(_compareByMountainThenDate);
  }

  CollectionReference<Map<String, dynamic>> _scheduleCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('scheduled_hikes');
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  String _scheduleCollectionPath(String userId) {
    return 'users/$userId/scheduled_hikes';
  }

  String _scheduleDocumentPath(String userId, String hikeId) {
    return scheduleDocumentPathForTesting(userId: userId, hikeId: hikeId);
  }

  String _userDocumentSchedulePath(String userId) {
    return 'users/$userId.$_userDocumentScheduleField';
  }

  static String _storageKeyForUser(String userId) {
    return '$_storageKeyPrefix$userId';
  }

  static List<ScheduledHike> _sorted(Iterable<ScheduledHike> hikes) {
    return hikes.toList()..sort(_compareByDate);
  }

  static List<ScheduledHike> _dedupeById(Iterable<ScheduledHike> hikes) {
    final byId = <String, ScheduledHike>{};
    for (final hike in hikes) {
      byId[hike.id] = hike;
    }

    return _sorted(byId.values);
  }

  static int _compareByDate(ScheduledHike first, ScheduledHike second) {
    final dateCompare = first.hikeDate.compareTo(second.hikeDate);
    if (dateCompare != 0) {
      return dateCompare;
    }

    return first.trailName.compareTo(second.trailName);
  }

  static int _compareByMountainThenDate(
    ScheduledHike first,
    ScheduledHike second,
  ) {
    final mountainCompare = first.mountainName.compareTo(second.mountainName);
    if (mountainCompare != 0) {
      return mountainCompare;
    }

    return _compareByDate(first, second);
  }

  static void _validateSchedulableDate(DateTime hikeDate) {
    final today = ScheduledHike.manilaDateForInstant(DateTime.now());
    final normalizedHikeDate = ScheduledHike.dateOnly(hikeDate);

    if (normalizedHikeDate.isBefore(today)) {
      throw ArgumentError.value(
        hikeDate,
        'hike.hikeDate',
        'New hike schedules must be for today or a future date.',
      );
    }
  }

  static String _firebaseMessage(Object error, {required String fallback}) {
    if (error is HikeScheduleException) {
      return error.message;
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => _permissionMessage,
        'unauthorized' => _permissionMessage,
        'unavailable' => 'Network connection is unavailable. Please try again.',
        'network-request-failed' =>
          'Network connection is unavailable. Please try again.',
        'deadline-exceeded' =>
          'Network connection is unavailable. Please try again.',
        'unauthenticated' => 'Please sign in first before scheduling a hike.',
        _ => fallback,
      };
    }

    return fallback;
  }

  static String _errorSummary(Object error) {
    if (error is FirebaseException) {
      final message = error.message?.trim();
      final details = <String>[
        'code=${error.code}',
        'plugin=${error.plugin}',
        if (message != null && message.isNotEmpty) 'message=$message',
      ].join(', ');

      return '${error.runtimeType}($details)';
    }

    return error.runtimeType.toString();
  }

  static bool _isPermissionDenied(FirebaseException error) {
    return error.code == 'permission-denied' || error.code == 'unauthorized';
  }

  bool _belongsToActiveUser(ScheduledHike hike) {
    return _belongsToUser(hike, _activeUserId);
  }

  static bool _belongsToUser(ScheduledHike hike, String? activeUserId) {
    if (activeUserId == null) {
      return false;
    }

    return hike.ownerUid == null || hike.ownerUid == activeUserId;
  }

  static String _readDocumentId(Map<String, dynamic> data) {
    final id = data['id']?.toString().trim();
    return id == null || id.isEmpty ? 'scheduled_hike' : id;
  }

  static void _logSchedule(String message) {
    if (kDebugMode) {
      debugPrint('[HikeSchedule] $message');
    }
  }

  static void _logFetch(String message) {
    if (kDebugMode) {
      debugPrint('[ScheduledHikes] $message');
    }
  }

  static void _logAuthenticatedUser(User user) {
    _logAccess('authenticated_uid_available', {
      'available': true,
      'uidHash': _safeIdentifier(user.uid),
      'emailMasked': _maskedEmail(user.email),
    });
  }

  static void _logAccess(String event, Map<String, Object?> fields) {
    if (!kDebugMode) {
      return;
    }

    final values = fields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    debugPrint('[ScheduledHikeAccess] $event $values');
  }

  static void _logAccessFailure({
    required String event,
    required String operation,
    required String firestorePath,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final fields = <String, Object?>{
      'operation': operation,
      'requested_firestore_path': _safePath(firestorePath),
      'errorType': error.runtimeType,
      if (error is FirebaseException) ...{
        'firebase_error_code': error.code,
        'firebase_error_message': error.message ?? 'none',
      },
      'stackTrace': _shortStackTrace(stackTrace),
    };
    _logAccess(event, fields);
  }

  static String _safePath(String path) {
    final segments = path.split('/');
    for (var index = 0; index < segments.length; index++) {
      if (index > 0 && segments[index - 1] == 'users') {
        segments[index] = _safeIdentifier(segments[index]);
      }
    }
    return segments.join('/');
  }

  static String _safeIdentifier(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return 'none';
    }
    if (text.length <= 8) {
      return '${text.substring(0, 1)}...${text.substring(text.length - 1)}';
    }
    return '${text.substring(0, 4)}...${text.substring(text.length - 4)}';
  }

  static String _maskedEmail(String? email) {
    final value = email?.trim();
    if (value == null || value.isEmpty) {
      return 'none';
    }
    final atIndex = value.indexOf('@');
    if (atIndex <= 0 || atIndex == value.length - 1) {
      return _safeIdentifier(value);
    }
    final local = value.substring(0, atIndex);
    final domain = value.substring(atIndex + 1);
    final maskedLocal = local.length <= 2
        ? '${local.substring(0, 1)}***'
        : '${local.substring(0, 1)}***${local.substring(local.length - 1)}';
    return '$maskedLocal@$domain';
  }

  static String _shortStackTrace(StackTrace stackTrace) {
    return stackTrace.toString().split('\n').take(4).join(' | ');
  }

  static bool _mountainMatches(
    ScheduledHike hike,
    String normalizedCurrentMountainId,
  ) {
    return _mountainIdentityKeys(hike).contains(normalizedCurrentMountainId);
  }

  static Set<String> _mountainIdentityKeys(ScheduledHike hike) {
    return <String>{
      _normalizeMountainId(hike.mountainId),
      _normalizeMountainId(hike.mountainName),
    }..removeWhere((value) => value == 'unknown-mountain');
  }

  static Set<String> _trailIdentityKeys({
    required String trailId,
    required String mountainId,
    String? trailName,
  }) {
    final keys = <String>{};

    void addIdentity(String value) {
      final normalized = _normalizeTrailIdentity(value);
      if (normalized.isEmpty) {
        return;
      }

      keys.add(normalized);
      keys.add(_stripGenericTrailSuffix(normalized));

      final withoutMountainPrefix = _stripMountainPrefix(
        normalized,
        mountainId,
      );
      keys.add(withoutMountainPrefix);
      keys.add(_stripGenericTrailSuffix(withoutMountainPrefix));
    }

    addIdentity(trailId);
    if (trailName != null) {
      addIdentity(trailName);
    }

    keys.removeWhere((value) => value.isEmpty);
    return keys;
  }

  static String _stripGenericTrailSuffix(String value) {
    return value.replaceAll(RegExp(r'-(trail|trails|route)$'), '');
  }

  static String _stripMountainPrefix(String value, String mountainId) {
    for (final prefix in _mountainTrailPrefixes(mountainId)) {
      final expectedPrefix = '$prefix-';
      if (value.startsWith(expectedPrefix)) {
        return value.substring(expectedPrefix.length);
      }
    }

    return value;
  }

  static Set<String> _mountainTrailPrefixes(String mountainId) {
    final displayName = MountainScheduleIdentity.displayNameForMountainId(
      mountainId,
    );
    final normalizedDisplayName = _normalizeTrailIdentity(displayName);
    final withoutMtPrefix = mountainId.replaceFirst(RegExp(r'^mt-'), '');
    final prefixes = <String>{
      mountainId,
      withoutMtPrefix,
      normalizedDisplayName,
      normalizedDisplayName.replaceFirst(RegExp(r'^mt-'), ''),
    };

    for (final value in List<String>.from(prefixes)) {
      final segments = value.split('-').where((segment) => segment.isNotEmpty);
      if (segments.isNotEmpty) {
        prefixes.add(segments.first);
      }
    }

    prefixes.removeWhere((value) => value.isEmpty);
    return prefixes;
  }

  static String _normalizeMountainId(String value) {
    return MountainScheduleIdentity.normalizeMountainId(value);
  }

  static String _normalizeTrailIdentity(String value) {
    var normalized = value.trim().toLowerCase();
    normalized = normalized.replaceAll('&', 'and');
    normalized = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized;
  }

  static void _logStartNavigationEligibility({
    required String currentMountainId,
    required String currentTrailId,
    required Set<String> currentTrailKeys,
    required ScheduledHike scheduledHike,
    required Set<String> scheduledTrailKeys,
    required String scheduledDateKey,
    required String todayKey,
    required bool userMatch,
    required bool mountainMatch,
    required bool trailMatch,
    required bool dateMatch,
    required bool statusMatch,
    required bool eligible,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[StartNavigation] currentMountainId=$currentMountainId '
      'scheduledMountainId=${scheduledHike.mountainId} '
      'mountainMatch=$mountainMatch',
    );
    debugPrint(
      '[StartNavigation] currentTrailId=$currentTrailId '
      'scheduledTrailId=${scheduledHike.trailId} '
      'trailMatch=$trailMatch',
    );
    debugPrint(
      '[StartNavigation] scheduledDateKey=$scheduledDateKey '
      'currentLocalDateKey=$todayKey status=${scheduledHike.status}',
    );
    debugPrint(
      '[StartNavigation] userMatch=$userMatch dateMatch=$dateMatch '
      'statusMatch=$statusMatch eligible=$eligible',
    );
    debugPrint(
      '[StartNavigation] currentTrailKeys=${_formatIdentityKeys(currentTrailKeys)} '
      'scheduledTrailKeys=${_formatIdentityKeys(scheduledTrailKeys)}',
    );
    if (!eligible) {
      debugPrint(
        '[StartNavigation] failedComparisons=${_failedComparisons(userMatch: userMatch, mountainMatch: mountainMatch, trailMatch: trailMatch, dateMatch: dateMatch, statusMatch: statusMatch)}',
      );
    }
  }

  static void _logStartNavigationNoSchedules({
    required String currentMountainId,
    required String currentTrailId,
    required String todayKey,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[StartNavigation] currentMountainId=$currentMountainId '
      'currentTrailId=$currentTrailId currentLocalDateKey=$todayKey '
      'eligible=false failedComparisons=no_scheduled_hikes',
    );
  }

  static String _formatIdentityKeys(Set<String> keys) {
    final sortedKeys = keys.toList()..sort();
    return sortedKeys.join(',');
  }

  static String _failedComparisons({
    required bool userMatch,
    required bool mountainMatch,
    required bool trailMatch,
    required bool dateMatch,
    required bool statusMatch,
  }) {
    final failed = <String>[
      if (!userMatch) 'user',
      if (!mountainMatch) 'mountain',
      if (!trailMatch) 'trail',
      if (!dateMatch) 'date',
      if (!statusMatch) 'status',
    ];

    return failed.isEmpty ? 'none' : failed.join(',');
  }
}
