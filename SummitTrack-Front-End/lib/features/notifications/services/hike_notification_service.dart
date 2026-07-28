import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/routing/app_route_observer.dart';
import '../../../core/routing/app_routes.dart';
import '../../../firebase_options.dart';
import '../../hike/models/scheduled_hike.dart';
import '../../hike/services/hike_schedule_store.dart';

const bool notificationDiagnostics = bool.fromEnvironment(
  'NOTIFICATION_DIAGNOSTICS',
);

String buildHikeReminderEventKey({
  required String uid,
  required String hikeId,
  required String hikeDateKey,
  required String deviceId,
}) {
  return '$uid|$hikeId|$hikeDateKey|$deviceId';
}

String hikeReminderEventDocumentId(String eventKey) {
  return sha256.convert(utf8.encode(eventKey)).toString();
}

@pragma('vm:entry-point')
Future<void> summitTrackFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await HikeNotificationService.instance.handleBackgroundRemoteMessage(
      message,
    );
  } catch (error) {
    if (notificationDiagnostics || kDebugMode) {
      debugPrint(
        '[HikeNotifications] background_message_failed '
        'error=${error.runtimeType}',
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> summitTrackLocalNotificationBackgroundTap(
  NotificationResponse response,
) async {
  final payload = response.payload?.trim();
  if (payload == null || payload.isEmpty) {
    return;
  }
  await _persistBackgroundNotificationTap(payload);
}

Future<void> _persistBackgroundNotificationTap(String payload) async {
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    await preferences.setString(
      HikeNotificationService.pendingTapPreferenceKey,
      payload,
    );
  } catch (error) {
    if (notificationDiagnostics || kDebugMode) {
      debugPrint(
        '[HikeNotifications] background_tap_persist_failed '
        'error=${error.runtimeType}',
      );
    }
  }
}

enum NotificationFailureKind {
  none,
  temporary,
  permanent,
  userAction,
  unsupported,
}

enum HikeReminderStatus {
  shown,
  scheduled,
  duplicate,
  skipped,
  retryableFailure,
  permanentFailure,
}

@immutable
class HikeReminderResult {
  const HikeReminderResult({
    required this.status,
    required this.message,
    this.notificationId,
    this.pendingScheduleConfirmed = false,
    this.cloudConfirmationWritten = false,
  });

  final HikeReminderStatus status;
  final String message;
  final int? notificationId;
  final bool pendingScheduleConfirmed;
  final bool cloudConfirmationWritten;

  bool get succeeded {
    return status == HikeReminderStatus.shown ||
        status == HikeReminderStatus.scheduled ||
        status == HikeReminderStatus.duplicate;
  }
}

class NotificationServiceException implements Exception {
  const NotificationServiceException({
    required this.message,
    required this.kind,
    required this.operation,
  });

  final String message;
  final NotificationFailureKind kind;
  final String operation;

  @override
  String toString() => '$operation: $message';
}

class HikeNotificationService extends ChangeNotifier
    with WidgetsBindingObserver {
  HikeNotificationService._({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  static final HikeNotificationService instance = HikeNotificationService._();

  static const String notificationType = 'scheduled_hike_today';
  static const String channelId = 'hike_day_reminders';
  static const String channelName = 'Hike Reminders';
  static const String channelDescription =
      'Date-based reminders for scheduled SummitTrack hikes.';
  static const String androidNotificationIcon = 'ic_stat_summittrack';
  static const String pendingTapPreferenceKey =
      'summittrack_pending_notification_tap_v1';

  static const _enabledPreferenceKey =
      'summittrack_hike_notifications_enabled_v1';
  static const _deviceIdPreferenceKey = 'summittrack_device_installation_id_v1';
  static const _notificationIdsPreferenceKey =
      'summittrack_hike_notification_ids_v1';
  static const _localEventStatePrefix =
      'summittrack_hike_notification_event_v2_';
  static const _consumedTapPrefix = 'summittrack_consumed_notification_tap_v1_';
  static const _internalReminderHour = 7;
  static const _internalReminderMinute = 0;
  static const _maximumNotificationId = 0x7ffffffe;
  static const _registrationRefreshInterval = Duration(hours: 12);
  static const _initializationTimeout = Duration(seconds: 15);
  static const _appVersion = '1.0.0';
  static const _buildNumber = '1';
  static const MethodChannel _settingsChannel = MethodChannel(
    'com.example.summittrack/notification_settings',
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  SharedPreferences? _preferences;

  Future<void>? _initializationFuture;
  Future<void>? _localInitializationFuture;
  Future<void>? _authStartFuture;
  Future<void>? _reconciliationFuture;
  Future<void>? _registrationFuture;
  Future<bool>? _timeZoneFuture;
  final Map<String, Future<HikeReminderResult>> _eventOperations =
      <String, Future<HikeReminderResult>>{};

  final List<String> _diagnosticEntries = <String>[];
  String _timeZoneName = 'unresolved';
  bool _timeZoneResolved = false;
  bool _serviceInitialized = false;
  bool _localNotificationsInitialized = false;
  bool _listenersInstalled = false;
  bool _authHandlingStarted = false;
  bool _userEnabledPreference = false;
  bool _effectiveEnabled = false;
  bool _channelBlocked = false;
  bool _reconciliationQueued = false;
  bool _navigationAttemptScheduled = false;
  bool _navigationInProgress = false;
  bool _disposed = false;
  int _navigationRetryCount = 0;
  String? _activeUid;
  HikeNotificationPayload? _pendingNavigationPayload;
  Timer? _navigationRetryTimer;

  bool get notificationsEnabled => _effectiveEnabled && !_channelBlocked;

  List<String> get diagnosticEntries =>
      List<String>.unmodifiable(_diagnosticEntries);

  Future<void> initialize() async {
    await ensureInitialized();
    await _startAuthHandling();
  }

  Future<void> ensureInitialized() {
    if (_serviceInitialized) {
      return SynchronousFuture<void>(null);
    }

    final existing = _initializationFuture;
    if (existing != null) {
      return existing;
    }

    late final Future<void> sharedFuture;
    sharedFuture = _initializeService().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      if (identical(_initializationFuture, sharedFuture)) {
        _initializationFuture = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _initializationFuture = sharedFuture;
    return sharedFuture;
  }

  Future<void> _initializeService() async {
    _recordDiagnostic('service_initialization_started');
    try {
      await _loadPreferences(reload: true);
      _userEnabledPreference =
          _preferences?.getBool(_enabledPreferenceKey) ?? false;
      _recordDiagnostic('notification_preference_loaded', {
        'enabled': _userEnabledPreference,
      });
      await _tryResolveTimeZone();
      await _ensureLocalNotificationsReady();
      await _setAutoInitEnabledPreservingState(_userEnabledPreference);
      _installListeners();
      _serviceInitialized = true;
      _recordDiagnostic('service_initialization_succeeded', {
        'timezone': _timeZoneName,
      });
    } catch (error, stackTrace) {
      final wrapped = error is NotificationServiceException
          ? error
          : NotificationServiceException(
              message: _safeErrorSummary(error),
              kind: _classifyFailure(error),
              operation: 'service-initialization',
            );
      _recordDiagnostic('service_initialization_failed', {
        'error': wrapped.message,
        'classification': wrapped.kind.name,
      });
      Error.throwWithStackTrace(wrapped, stackTrace);
    }
  }

  void _installListeners() {
    if (_listenersInstalled) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) {
      _startGuardedTask(
        'foreground_message_handling_failed',
        () => _handleForegroundRemoteMessage(message),
      );
    });
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _startGuardedTask(
        'opened_message_handling_failed',
        () => _handleRemoteNotificationTap(message),
      );
    });
    _listenersInstalled = true;
  }

  Future<void> _startAuthHandling() {
    final existing = _authStartFuture;
    if (existing != null) {
      return existing;
    }

    late final Future<void> sharedFuture;
    sharedFuture = _startAuthHandlingOnce().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      if (!_authHandlingStarted && identical(_authStartFuture, sharedFuture)) {
        _authStartFuture = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _authStartFuture = sharedFuture;
    return sharedFuture;
  }

  Future<void> _startAuthHandlingOnce() {
    if (_authHandlingStarted) {
      return SynchronousFuture<void>(null);
    }

    _authHandlingStarted = true;
    _activeUid = _auth.currentUser?.uid;
    _authSubscription = _auth.authStateChanges().listen((user) {
      _startGuardedTask(
        'auth_change_handling_failed',
        () => _handleAuthChanged(user),
      );
    });

    // Remote reconciliation, permission inspection, token work, and launch-tap
    // inspection are optional notification tasks. None of them may hold the
    // application startup Future or the first route open.
    _startGuardedTask('startup_reconciliation_failed', _requestReconciliation);
    _startGuardedTask(
      'initial_notification_launch_failed',
      _handleInitialNotificationLaunch,
    );
    _startGuardedTask(
      'token_subscription_sync_failed',
      _syncTokenRefreshSubscription,
    );
    _schedulePendingNavigationAttempt();
    _recordDiagnostic('notification_background_tasks_started');
    return SynchronousFuture<void>(null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startGuardedTask(
        'resume_reconciliation_failed',
        reconcileForCurrentUser,
      );
      _navigationRetryCount = 0;
      _schedulePendingNavigationAttempt();
    }
  }

  Future<NotificationEnableResult> enableFromSettings() async {
    try {
      await initialize();
    } catch (error) {
      return NotificationEnableResult.failure(
        'SummitTrack could not initialize notifications '
        '(${_safeErrorSummary(error)}). Please try again.',
        failureKind: _classifyFailure(error),
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      return const NotificationEnableResult.failure(
        'Please sign in before enabling hike notifications.',
        failureKind: NotificationFailureKind.userAction,
      );
    }

    final permission = await _requestSystemPermission();
    _recordPermissionDiagnostic('enable_permission_result', permission);
    if (!permission.allowed) {
      if (permission.appNotificationsExplicitlyDisabled) {
        await _applyExplicitSystemDisable(user.uid);
      } else if (permission.channelBlocked) {
        _channelBlocked = true;
        _setEffectiveEnabled(false);
      }

      return NotificationEnableResult.failure(
        permission.message,
        failureKind: permission.failureKind,
        openSettingsSuggested: permission.openSettingsSuggested,
      );
    }

    final previousPreference = _userEnabledPreference;
    final previousEffectiveState = _effectiveEnabled;
    try {
      await _setAutoInitEnabledPreservingState(true);
      await _registerCurrentDevice(force: true);
    } catch (error) {
      _recordDiagnostic('device_registration_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
      _userEnabledPreference = previousPreference;
      _setEffectiveEnabled(previousEffectiveState);
      return NotificationEnableResult.failure(
        _registrationFailureMessage(error),
        failureKind: _classifyFailure(error),
      );
    }

    if (!await _setEnabledPreference(true)) {
      _userEnabledPreference = previousPreference;
      _setEffectiveEnabled(previousEffectiveState);
      if (!previousPreference) {
        await _disableCloudDevice(user.uid);
        await _deleteFcmTokenQuietly();
        await _setAutoInitEnabledPreservingState(false);
      }
      return const NotificationEnableResult.failure(
        'SummitTrack registered this device but could not save the local '
        'notification setting. Please try again.',
        failureKind: NotificationFailureKind.temporary,
      );
    }

    _channelBlocked = false;
    _setEffectiveEnabled(true);
    await _syncTokenRefreshSubscription();
    await _requestReconciliation();
    return const NotificationEnableResult.success(
      'Hike-day reminders are enabled.',
    );
  }

  Future<void> declineFromSettings() async {
    await ensureInitialized();
  }

  Future<NotificationDisableResult> disableFromSettings() async {
    try {
      await initialize();
    } catch (error) {
      return NotificationDisableResult.failure(
        'SummitTrack could not initialize notifications '
        '(${_safeErrorSummary(error)}). Please try again.',
      );
    }

    final uid = _auth.currentUser?.uid ?? _activeUid;
    final previousPreference = _userEnabledPreference;
    final previousEffectiveState = _effectiveEnabled;
    final previousChannelBlocked = _channelBlocked;

    if (!await _setEnabledPreference(false)) {
      return const NotificationDisableResult.failure(
        'The local notification preference could not be saved.',
      );
    }

    _channelBlocked = false;
    _setEffectiveEnabled(false);
    await _syncTokenRefreshSubscription();

    try {
      if (uid != null) {
        await _cancelAllHikeNotificationsInternal(
          uid: uid,
          failOnLocalCleanupError: true,
        );
      } else {
        await _cancelAllHikeNotificationsInternal(
          failOnLocalCleanupError: true,
        );
      }
    } catch (error) {
      await _restoreAfterDisableFailure(
        uid: uid,
        previousPreference: previousPreference,
        previousEffectiveState: previousEffectiveState,
        previousChannelBlocked: previousChannelBlocked,
      );
      return NotificationDisableResult.failure(_disableFailureMessage(error));
    }

    if (uid != null) {
      await _disableCloudDevice(uid);
    }
    await _deleteFcmTokenQuietly();
    await _setAutoInitEnabledPreservingState(false);
    return const NotificationDisableResult.success(
      'Hike reminders are turned off.',
    );
  }

  Future<void> handleLogout() async {
    try {
      await initialize();
    } catch (error) {
      _recordDiagnostic('logout_initialization_failed', {
        'classification': _classifyFailure(error).name,
      });
      return;
    }

    final uid = _auth.currentUser?.uid ?? _activeUid;
    if (uid == null) {
      await _cancelAllHikeNotificationsInternal();
      return;
    }

    await _cancelAllHikeNotificationsInternal(uid: uid);
    await _disableCloudDevice(uid);
  }

  Future<void> reconcileForCurrentUser() async {
    try {
      await initialize();
    } catch (error) {
      _recordDiagnostic('reconciliation_skipped', {
        'reason': 'initialization-failed',
        'classification': _classifyFailure(error).name,
      });
      return;
    }
    await _requestReconciliation();
  }

  Future<void> _requestReconciliation() {
    final running = _reconciliationFuture;
    if (running != null) {
      _reconciliationQueued = true;
      _recordDiagnostic('reconciliation_queued');
      return running;
    }

    late final Future<void> sharedFuture;
    sharedFuture = _runReconciliationLoop().whenComplete(() {
      if (identical(_reconciliationFuture, sharedFuture)) {
        _reconciliationFuture = null;
      }
    });
    _reconciliationFuture = sharedFuture;
    return sharedFuture;
  }

  Future<void> _runReconciliationLoop() async {
    do {
      _reconciliationQueued = false;
      await _reconcileOnce();
    } while (_reconciliationQueued);
  }

  Future<void> _reconcileOnce() async {
    _recordDiagnostic('reconciliation_started');
    await _loadPreferences(reload: true);
    _userEnabledPreference =
        _preferences?.getBool(_enabledPreferenceKey) ?? false;
    await _removeExpiredNotificationsInternal();

    final user = _auth.currentUser;
    if (user == null) {
      _setEffectiveEnabled(false);
      await _cancelAllHikeNotificationsInternal();
      await _syncTokenRefreshSubscription();
      _recordDiagnostic('reconciliation_completed', {'state': 'signed-out'});
      return;
    }

    if (!_userEnabledPreference) {
      _channelBlocked = false;
      _setEffectiveEnabled(false);
      await _cancelAllHikeNotificationsInternal(uid: user.uid);
      await _disableCloudDevice(user.uid);
      await _deleteFcmTokenQuietly();
      await _setAutoInitEnabledPreservingState(false);
      await _syncTokenRefreshSubscription();
      _recordDiagnostic('reconciliation_completed', {'state': 'disabled'});
      return;
    }

    final permission = await _checkSystemPermission();
    _recordPermissionDiagnostic('reconciliation_permission_result', permission);
    if (permission.appNotificationsExplicitlyDisabled) {
      await _applyExplicitSystemDisable(user.uid);
      _recordDiagnostic('reconciliation_completed', {
        'state': 'system-disabled',
        'classification': NotificationFailureKind.permanent.name,
      });
      return;
    }

    if (permission.channelBlocked) {
      _channelBlocked = true;
      _setEffectiveEnabled(false);
      await _syncTokenRefreshSubscription();
      _recordDiagnostic('reconciliation_completed', {
        'state': 'channel-disabled',
        'classification': NotificationFailureKind.userAction.name,
      });
      return;
    }

    if (!permission.allowed) {
      _channelBlocked = false;
      _setEffectiveEnabled(_userEnabledPreference);
      await _syncTokenRefreshSubscription();
      _recordDiagnostic('reconciliation_skipped', {
        'reason': 'permission-unconfirmed',
        'classification': permission.failureKind.name,
      });
      return;
    }

    _channelBlocked = false;
    _setEffectiveEnabled(true);
    try {
      await _registerCurrentDevice();
    } catch (error) {
      _recordDiagnostic('device_registration_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
    }

    await _reconcileScheduledHikesForUser(user.uid);
    await _syncTokenRefreshSubscription();
    _schedulePendingNavigationAttempt();
    _recordDiagnostic('reconciliation_completed', {'state': 'enabled'});
  }

  Future<void> reconcileScheduledHikes(
    String uid,
    Iterable<ScheduledHike> hikes,
  ) async {
    await initialize();
    await _reconcileScheduledHikesInternal(uid, hikes);
  }

  Future<void> _reconcileScheduledHikesInternal(
    String uid,
    Iterable<ScheduledHike> hikes,
  ) async {
    if (!_effectiveEnabled ||
        _channelBlocked ||
        _auth.currentUser?.uid != uid) {
      return;
    }

    final validHikes = hikes.where((hike) => _isTodayOrFuture(hike.hikeDate));
    final validMappingKeys = <String>{};
    for (final hike in validHikes) {
      validMappingKeys.add(_mappingKey(uid, hike.id));
      try {
        await scheduleHikeNotification(hike.copyWith(ownerUid: uid));
      } catch (error) {
        _recordDiagnostic('hike_schedule_reconciliation_failed', {
          'classification': _classifyFailure(error).name,
          'error': _safeErrorSummary(error),
        });
      }
    }
    await _cancelUnknownAccountNotifications(uid, validMappingKeys);
  }

  Future<HikeReminderResult> scheduleHikeNotification(
    ScheduledHike hike, {
    bool replaceExisting = false,
  }) async {
    try {
      await initialize();
    } catch (error) {
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message:
            'Notification initialization failed: ${_safeErrorSummary(error)}',
      );
    }

    final uid = hike.ownerUid ?? _auth.currentUser?.uid;
    if (uid == null ||
        uid != _auth.currentUser?.uid ||
        !_userEnabledPreference ||
        !_effectiveEnabled ||
        _channelBlocked) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'Hike notifications are not currently enabled.',
      );
    }

    final hikeDateKey = ScheduledHike.dateKey(hike.hikeDate);
    if (_isExpired(hikeDateKey)) {
      await _cancelHikeNotificationInternal(uid: uid, hikeId: hike.id);
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The hike date has expired.',
      );
    }

    final deviceId = await _deviceId();
    final payload = _payloadForHike(uid: uid, hike: hike, deviceId: deviceId);
    return _runEventOperation(
      payload.eventKey,
      () => _scheduleOrShowHike(
        payload: payload,
        expectedHike: hike,
        replaceExisting: replaceExisting,
      ),
    );
  }

  Future<HikeReminderResult> _runEventOperation(
    String eventKey,
    Future<HikeReminderResult> Function() operation,
  ) {
    final running = _eventOperations[eventKey];
    if (running != null) {
      return running;
    }

    late final Future<HikeReminderResult> sharedFuture;
    sharedFuture = operation().whenComplete(() {
      if (identical(_eventOperations[eventKey], sharedFuture)) {
        _eventOperations.remove(eventKey);
      }
    });
    _eventOperations[eventKey] = sharedFuture;
    return sharedFuture;
  }

  Future<HikeReminderResult> _scheduleOrShowHike({
    required HikeNotificationPayload payload,
    required ScheduledHike expectedHike,
    required bool replaceExisting,
  }) async {
    final permission = await _checkSystemPermission();
    _recordPermissionDiagnostic('schedule_permission_result', permission);
    if (!permission.allowed) {
      return HikeReminderResult(
        status: permission.failureKind == NotificationFailureKind.temporary
            ? HikeReminderStatus.retryableFailure
            : HikeReminderStatus.permanentFailure,
        message: permission.message,
      );
    }

    ScheduledHike? storedHike;
    try {
      storedHike = await _loadExactHike(payload);
    } catch (error) {
      return HikeReminderResult(
        status: _classifyFailure(error) == NotificationFailureKind.temporary
            ? HikeReminderStatus.retryableFailure
            : HikeReminderStatus.permanentFailure,
        message:
            'The scheduled hike could not be validated '
            '(${_safeErrorSummary(error)}).',
      );
    }
    if (storedHike == null ||
        ScheduledHike.dateKey(storedHike.hikeDate) != payload.hikeDateKey) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The scheduled hike could not be validated.',
      );
    }

    final todayKey = _currentDateKey();
    if (payload.hikeDateKey == todayKey) {
      _recordDiagnostic('same_day_branch_entered', {
        'hikeDateKey': payload.hikeDateKey,
      });
      return _displayHikeReminderOnce(payload, source: 'local-same-day');
    }

    _recordDiagnostic('same_day_branch_skipped', {
      'hikeDateKey': payload.hikeDateKey,
    });
    if (payload.hikeDateKey.compareTo(todayKey) < 0) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The hike date has expired.',
      );
    }

    if (!await _tryResolveTimeZone()) {
      return const HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message: 'The device timezone could not be resolved yet.',
      );
    }

    final notificationId = await _notificationIdFor(
      uid: payload.uid,
      hikeId: payload.hikeId,
    );
    final existingState = await _readLocalEventState(payload.eventKey);
    if (!replaceExisting &&
        existingState != null &&
        existingState.status == 'scheduled') {
      final pending = await _pendingRequestExists(notificationId);
      if (pending) {
        await _writeCloudEventConfirmation(
          payload: payload,
          notificationId: notificationId,
          status: 'scheduled',
          localScheduleConfirmed: true,
        );
        return HikeReminderResult(
          status: HikeReminderStatus.duplicate,
          message: 'The future hike reminder is already scheduled.',
          notificationId: notificationId,
          pendingScheduleConfirmed: true,
          cloudConfirmationWritten: true,
        );
      }
      await _removeLocalEventState(payload.eventKey);
      await _writeCloudEventConfirmation(
        payload: payload,
        notificationId: notificationId,
        status: 'retryable',
        localScheduleConfirmed: false,
      );
    }

    final scheduledDate = _scheduledDateFor(expectedHike.hikeDate);
    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      return const HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message: 'SummitTrack refused to schedule a past notification time.',
      );
    }

    final timeoutAfter = _expirationAfterPosting(scheduledDate);
    _recordDiagnostic('zoned_schedule_started', {
      'hikeDateKey': payload.hikeDateKey,
      'notificationId': notificationId,
      'timezone': _timeZoneName,
    });
    try {
      await _localNotifications.zonedSchedule(
        notificationId,
        _notificationTitle(),
        _notificationBody(
          firstName: _firstName(_auth.currentUser),
          mountainName: storedHike.mountainName,
        ),
        scheduledDate,
        _notificationDetails(
          hikeId: payload.hikeId,
          timeoutAfter: timeoutAfter,
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload.toJsonString(),
      );
      _recordDiagnostic('zoned_schedule_succeeded', {
        'notificationId': notificationId,
      });
    } catch (error) {
      _recordDiagnostic('zoned_schedule_failed', {
        'notificationId': notificationId,
        'error': _safeErrorSummary(error),
        'classification': _classifyFailure(error).name,
      });
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message:
            'Future reminder scheduling failed: ${_safeErrorSummary(error)}',
        notificationId: notificationId,
      );
    }

    final pendingFound = await _pendingRequestExists(notificationId);
    _recordDiagnostic(
      pendingFound
          ? 'expected_pending_notification_found'
          : 'expected_pending_notification_missing',
      {'notificationId': notificationId},
    );
    if (!pendingFound) {
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message: 'The platform did not retain the scheduled reminder.',
        notificationId: notificationId,
      );
    }

    final localStateWritten = await _writeLocalEventState(
      _LocalEventState(
        eventKey: payload.eventKey,
        uid: payload.uid,
        hikeId: payload.hikeId,
        hikeDateKey: payload.hikeDateKey,
        notificationId: notificationId,
        status: 'scheduled',
      ),
    );
    final cloudConfirmationWritten = await _writeCloudEventConfirmation(
      payload: payload,
      notificationId: notificationId,
      status: 'scheduled',
      localScheduleConfirmed: true,
    );

    if (!localStateWritten && !cloudConfirmationWritten) {
      await _cancelNotificationId(notificationId, hikeId: payload.hikeId);
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message:
            'The reminder was cancelled because duplicate-prevention '
            'state could not be saved.',
        notificationId: notificationId,
        pendingScheduleConfirmed: true,
      );
    }

    return HikeReminderResult(
      status: HikeReminderStatus.scheduled,
      message: 'The future hike reminder is scheduled and verified.',
      notificationId: notificationId,
      pendingScheduleConfirmed: true,
      cloudConfirmationWritten: cloudConfirmationWritten,
    );
  }

  Future<HikeReminderResult> handleSavedHike(ScheduledHike hike) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'No authenticated user is available.',
      );
    }
    try {
      return await scheduleHikeNotification(
        hike.copyWith(ownerUid: user.uid),
        replaceExisting: true,
      );
    } catch (error) {
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message:
            'The hike was saved, but notification setup is temporarily '
            'unavailable (${_safeErrorSummary(error)}).',
      );
    }
  }

  Future<HikeReminderResult> handleUpdatedHike({
    required ScheduledHike oldHike,
    required ScheduledHike updatedHike,
  }) async {
    await initialize();
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'No authenticated user is available.',
      );
    }

    await _cancelHikeNotificationInternal(uid: uid, hikeId: oldHike.id);
    return handleSavedHike(updatedHike.copyWith(ownerUid: uid));
  }

  Future<void> handleDeletedHike({
    required String uid,
    required String hikeId,
  }) async {
    await initialize();
    await _cancelHikeNotificationInternal(uid: uid, hikeId: hikeId);
  }

  Future<void> cancelHikeNotification({
    required String uid,
    required String hikeId,
  }) async {
    await initialize();
    await _cancelHikeNotificationInternal(uid: uid, hikeId: hikeId);
  }

  Future<void> _cancelHikeNotificationInternal({
    required String uid,
    required String hikeId,
  }) async {
    final notificationId = await _notificationIdFor(uid: uid, hikeId: hikeId);
    await _cancelNotificationId(notificationId, hikeId: hikeId);
    final states = await _readLocalEventStates(uid: uid, hikeId: hikeId);
    for (final state in states) {
      await _removeLocalEventState(state.eventKey);
      await _deleteCloudEventState(state);
    }
  }

  Future<void> removeDeliveredHikeNotification({
    required String uid,
    required String hikeId,
  }) async {
    await initialize();
    final notificationId = await _notificationIdFor(uid: uid, hikeId: hikeId);
    await _cancelNotificationId(notificationId, hikeId: hikeId);
  }

  Future<void> cancelAllHikeNotifications({String? uid}) async {
    await initialize();
    await _cancelAllHikeNotificationsInternal(uid: uid);
  }

  Future<void> _cancelAllHikeNotificationsInternal({
    String? uid,
    bool failOnLocalCleanupError = false,
  }) async {
    if (!_localNotificationsInitialized) {
      try {
        await _ensureLocalNotificationsReady();
      } catch (error) {
        _recordDiagnostic('notification_cleanup_failed', {
          'error': _safeErrorSummary(error),
        });
        if (failOnLocalCleanupError) {
          throw NotificationServiceException(
            message: 'Scheduled hike reminders could not be cancelled.',
            kind: _classifyFailure(error),
            operation: 'notification-cleanup',
          );
        }
        return;
      }
    }

    final mappedIds = await _knownNotificationIds(uid: uid);
    for (final entry in mappedIds.entries) {
      try {
        await _cancelNotificationId(entry.value, hikeId: entry.key.$2);
      } catch (error) {
        _recordDiagnostic('mapped_notification_cancel_failed', {
          'notificationId': entry.value,
          'classification': _classifyFailure(error).name,
        });
        if (failOnLocalCleanupError) {
          throw NotificationServiceException(
            message: 'Scheduled hike reminders could not be cancelled.',
            kind: _classifyFailure(error),
            operation: 'notification-cancel',
          );
        }
      }
    }

    final pending = await () async {
      try {
        return await _localNotifications.pendingNotificationRequests();
      } catch (error) {
        _recordDiagnostic('pending_cleanup_failed', {
          'error': _safeErrorSummary(error),
        });
        if (failOnLocalCleanupError) {
          throw NotificationServiceException(
            message: 'Scheduled hike reminders could not be verified.',
            kind: _classifyFailure(error),
            operation: 'pending-notification-cleanup',
          );
        }
        return const <PendingNotificationRequest>[];
      }
    }();

    for (final request in pending) {
      final payload = HikeNotificationPayload.tryParse(request.payload);
      if (payload != null && (uid == null || payload.uid == uid)) {
        try {
          await _cancelNotificationId(request.id, hikeId: payload.hikeId);
        } catch (error) {
          _recordDiagnostic('pending_notification_cancel_failed', {
            'notificationId': request.id,
            'classification': _classifyFailure(error).name,
          });
          if (failOnLocalCleanupError) {
            throw NotificationServiceException(
              message: 'Scheduled hike reminders could not be cancelled.',
              kind: _classifyFailure(error),
              operation: 'notification-cancel',
            );
          }
        }
      }
    }

    final states = await _readLocalEventStates(uid: uid);
    for (final state in states) {
      await _removeLocalEventState(state.eventKey);
      await _deleteCloudEventState(state);
    }

    if (failOnLocalCleanupError) {
      await _assertNoPendingHikeNotifications(uid: uid, mappedIds: mappedIds);
    }
  }

  Future<void> _assertNoPendingHikeNotifications({
    required String? uid,
    required Map<(String, String), int> mappedIds,
  }) async {
    try {
      final knownIds = mappedIds.values.toSet();
      final pending = await _localNotifications.pendingNotificationRequests();
      final remaining = pending.where((request) {
        if (knownIds.contains(request.id)) {
          return true;
        }

        final payload = HikeNotificationPayload.tryParse(request.payload);
        return payload != null && (uid == null || payload.uid == uid);
      }).length;

      if (remaining > 0) {
        throw const NotificationServiceException(
          message: 'Some scheduled hike reminders could not be cancelled.',
          kind: NotificationFailureKind.temporary,
          operation: 'notification-cancel-verification',
        );
      }
    } catch (error) {
      if (error is NotificationServiceException) {
        rethrow;
      }

      _recordDiagnostic('pending_cancel_verification_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
      throw NotificationServiceException(
        message: 'Scheduled hike reminders could not be verified.',
        kind: _classifyFailure(error),
        operation: 'notification-cancel-verification',
      );
    }
  }

  Future<void> removeExpiredNotifications() async {
    await initialize();
    await _removeExpiredNotificationsInternal();
  }

  Future<void> _removeExpiredNotificationsInternal() async {
    if (!_localNotificationsInitialized) {
      return;
    }

    final todayKey = _currentDateKey();
    final expiredStates = (await _readLocalEventStates()).where(
      (state) => state.hikeDateKey.compareTo(todayKey) < 0,
    );
    for (final state in expiredStates) {
      await _cancelNotificationId(state.notificationId, hikeId: state.hikeId);
      await _removeLocalEventState(state.eventKey);
      await _deleteCloudEventState(state);
    }

    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      for (final request in pending) {
        final payload = HikeNotificationPayload.tryParse(request.payload);
        if (payload != null && payload.hikeDateKey.compareTo(todayKey) < 0) {
          await _cancelNotificationId(request.id, hikeId: payload.hikeId);
        }
      }
    } catch (error) {
      _recordDiagnostic('expired_pending_cleanup_failed', {
        'error': _safeErrorSummary(error),
      });
    }

    try {
      final active = await _localNotifications.getActiveNotifications();
      for (final notification in active) {
        final payload = HikeNotificationPayload.tryParse(notification.payload);
        if (payload != null && payload.hikeDateKey.compareTo(todayKey) < 0) {
          final id = notification.id;
          if (id != null) {
            await _cancelNotificationId(id, hikeId: payload.hikeId);
          }
        }
      }
    } catch (error) {
      _recordDiagnostic('expired_delivered_cleanup_failed', {
        'error': _safeErrorSummary(error),
      });
    }
  }

  Future<void> handleBackgroundRemoteMessage(RemoteMessage message) async {
    await _loadPreferences(reload: true);
    if (!(_preferences?.getBool(_enabledPreferenceKey) ?? false)) {
      return;
    }

    await _tryResolveTimeZone();
    try {
      await _ensureLocalNotificationsReady();
    } catch (error) {
      _recordDiagnostic('background_initialization_failed', {
        'error': _safeErrorSummary(error),
      });
      return;
    }

    final payload = HikeNotificationPayload.fromRemoteMessage(message);
    if (payload == null) {
      return;
    }
    final user = await _currentUserAfterRestore();
    if (user?.uid != payload.uid) {
      return;
    }
    final deviceId = await _deviceId();
    if (payload.deviceId != deviceId) {
      return;
    }

    await _runEventOperation(
      payload.eventKey,
      () => _displayHikeReminderOnce(payload, source: 'remote-background'),
    );
  }

  Future<void> _handleForegroundRemoteMessage(RemoteMessage message) async {
    final payload = HikeNotificationPayload.fromRemoteMessage(message);
    if (payload == null) {
      return;
    }
    final deviceId = await _deviceId();
    if (payload.deviceId != deviceId) {
      return;
    }
    await _runEventOperation(
      payload.eventKey,
      () => _displayHikeReminderOnce(payload, source: 'remote-foreground'),
    );
  }

  Future<HikeReminderResult> _displayHikeReminderOnce(
    HikeNotificationPayload payload, {
    required String source,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != payload.uid) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The notification belongs to a different account.',
      );
    }

    final deviceId = await _deviceId();
    if (deviceId != payload.deviceId ||
        payload.eventKey !=
            buildHikeReminderEventKey(
              uid: payload.uid,
              hikeId: payload.hikeId,
              hikeDateKey: payload.hikeDateKey,
              deviceId: deviceId,
            )) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The notification does not belong to this installation.',
      );
    }

    final currentDateKey = _currentDateKey();
    if (payload.hikeDateKey != currentDateKey) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The notification is not valid for the current local date.',
      );
    }

    await _loadPreferences(reload: true);
    if (!(_preferences?.getBool(_enabledPreferenceKey) ?? false)) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'Hike notifications are turned off.',
      );
    }

    final permission = await _checkSystemPermission();
    _recordPermissionDiagnostic('display_permission_result', permission);
    if (!permission.allowed) {
      return HikeReminderResult(
        status: permission.failureKind == NotificationFailureKind.temporary
            ? HikeReminderStatus.retryableFailure
            : HikeReminderStatus.permanentFailure,
        message: permission.message,
      );
    }

    ScheduledHike? hike;
    try {
      hike = await _loadExactHike(payload);
    } catch (error) {
      return HikeReminderResult(
        status: _classifyFailure(error) == NotificationFailureKind.temporary
            ? HikeReminderStatus.retryableFailure
            : HikeReminderStatus.permanentFailure,
        message:
            'The hike could not be validated '
            '(${_safeErrorSummary(error)}).',
      );
    }
    if (hike == null ||
        ScheduledHike.dateKey(hike.hikeDate) != currentDateKey) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The hike no longer exists for today.',
      );
    }

    final localState = await _readLocalEventState(payload.eventKey);
    if (localState != null &&
        (localState.status == 'displayed' ||
            localState.status == 'scheduled' ||
            localState.status == 'claiming')) {
      return HikeReminderResult(
        status: HikeReminderStatus.duplicate,
        message: 'This hike reminder was already scheduled or displayed.',
        notificationId: localState.notificationId,
      );
    }

    final notificationId = await _notificationIdFor(
      uid: payload.uid,
      hikeId: payload.hikeId,
    );
    final localSource = source.startsWith('local-');
    final claimed = await _claimCloudEvent(
      payload: payload,
      notificationId: notificationId,
      source: source,
      localScheduleConfirmed: localSource,
    );
    if (claimed == null) {
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message: 'Duplicate-prevention state is temporarily unavailable.',
        notificationId: notificationId,
      );
    }
    if (!claimed) {
      return HikeReminderResult(
        status: HikeReminderStatus.duplicate,
        message: 'Another notification path already claimed this reminder.',
        notificationId: notificationId,
      );
    }

    final claimingState = _LocalEventState(
      eventKey: payload.eventKey,
      uid: payload.uid,
      hikeId: payload.hikeId,
      hikeDateKey: payload.hikeDateKey,
      notificationId: notificationId,
      status: 'claiming',
    );
    await _writeLocalEventState(claimingState);

    _recordDiagnostic('show_started', {
      'notificationId': notificationId,
      'source': source,
    });
    try {
      await _showNotification(
        id: notificationId,
        title: _notificationTitle(),
        body: _notificationBody(
          firstName: _firstName(user),
          mountainName: hike.mountainName,
        ),
        hikeId: payload.hikeId,
        payload: payload.toJsonString(),
      );
      _recordDiagnostic('show_succeeded', {
        'notificationId': notificationId,
        'source': source,
      });
    } catch (error) {
      await _releaseCloudEventClaim(
        payload: payload,
        notificationId: notificationId,
        error: error,
      );
      await _removeLocalEventState(payload.eventKey);
      _recordDiagnostic('show_failed', {
        'notificationId': notificationId,
        'error': _safeErrorSummary(error),
        'classification': _classifyFailure(error).name,
      });
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message:
            'The reminder could not be displayed: '
            '${_safeErrorSummary(error)}',
        notificationId: notificationId,
      );
    }

    await _writeLocalEventState(claimingState.copyWith(status: 'displayed'));
    await _markCloudEventDisplayed(
      payload: payload,
      notificationId: notificationId,
      localScheduleConfirmed: localSource,
    );
    return HikeReminderResult(
      status: HikeReminderStatus.shown,
      message: 'The hike-day reminder was displayed.',
      notificationId: notificationId,
      cloudConfirmationWritten: true,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String hikeId,
    required String payload,
  }) {
    return _localNotifications.show(
      id,
      title,
      body,
      _notificationDetails(
        hikeId: hikeId,
        timeoutAfter: _timeoutUntilNextLocalDay(),
      ),
      payload: payload,
    );
  }

  Future<bool?> _claimCloudEvent({
    required HikeNotificationPayload payload,
    required int notificationId,
    required String source,
    required bool localScheduleConfirmed,
  }) async {
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final claimedUntilMillis = _nextLocalMidnight().millisecondsSinceEpoch;
    final reference = _eventDocument(payload);
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(reference);
        final data = snapshot.data() ?? const <String, dynamic>{};
        final status = data['status']?.toString() ?? '';
        final existingClaimUntil =
            (data['claimedUntilMillis'] as num?)?.toInt() ?? 0;
        final confirmed = data['localScheduleConfirmed'] == true;

        if (status == 'displayed' ||
            confirmed && (status == 'scheduled' || status == 'claiming') ||
            status == 'claiming' && existingClaimUntil > nowMillis) {
          return false;
        }

        transaction.set(reference, {
          'eventKey': payload.eventKey,
          'type': notificationType,
          'uid': payload.uid,
          'deviceId': payload.deviceId,
          'hikeId': payload.hikeId,
          'hikeDateKey': payload.hikeDateKey,
          'status': 'claiming',
          'source': source,
          'notificationId': notificationId,
          'localScheduleConfirmed': localScheduleConfirmed,
          'claimedUntilMillis': claimedUntilMillis,
          'expiresAtMillis': claimedUntilMillis,
          'attempts': ((data['attempts'] as num?)?.toInt() ?? 0) + 1,
          'claimedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      });
    } catch (error) {
      _recordDiagnostic('event_claim_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
      return null;
    }
  }

  Future<bool> _writeCloudEventConfirmation({
    required HikeNotificationPayload payload,
    required int notificationId,
    required String status,
    required bool localScheduleConfirmed,
  }) async {
    try {
      await _eventDocument(payload).set({
        'eventKey': payload.eventKey,
        'type': notificationType,
        'uid': payload.uid,
        'deviceId': payload.deviceId,
        'hikeId': payload.hikeId,
        'hikeDateKey': payload.hikeDateKey,
        'status': status,
        'source': 'local-schedule',
        'notificationId': notificationId,
        'localScheduleConfirmed': localScheduleConfirmed,
        'claimedUntilMillis': 0,
        'expiresAtMillis': _midnightAfterDateKey(
          payload.hikeDateKey,
        ).millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
        if (localScheduleConfirmed) 'confirmedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (error) {
      _recordDiagnostic('local_schedule_confirmation_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
      return false;
    }
  }

  Future<void> _markCloudEventDisplayed({
    required HikeNotificationPayload payload,
    required int notificationId,
    required bool localScheduleConfirmed,
  }) async {
    try {
      await _eventDocument(payload).set({
        'status': 'displayed',
        'notificationId': notificationId,
        'localScheduleConfirmed': localScheduleConfirmed,
        'claimedUntilMillis': _nextLocalMidnight().millisecondsSinceEpoch,
        'expiresAtMillis': _nextLocalMidnight().millisecondsSinceEpoch,
        'displayedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'errorClass': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (error) {
      _recordDiagnostic('display_success_record_failed', {
        'classification': _classifyFailure(error).name,
      });
    }
  }

  Future<void> _releaseCloudEventClaim({
    required HikeNotificationPayload payload,
    required int notificationId,
    required Object error,
  }) async {
    try {
      await _eventDocument(payload).set({
        'status': 'retryable',
        'notificationId': notificationId,
        'localScheduleConfirmed': false,
        'claimedUntilMillis': 0,
        'errorClass': _safeErrorSummary(error),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (releaseError) {
      _recordDiagnostic('event_claim_release_failed', {
        'classification': _classifyFailure(releaseError).name,
      });
    }
  }

  DocumentReference<Map<String, dynamic>> _eventDocument(
    HikeNotificationPayload payload,
  ) {
    return _deviceDocument(payload.uid, deviceId: payload.deviceId)
        .collection('notificationEvents')
        .doc(hikeReminderEventDocumentId(payload.eventKey));
  }

  Future<void> _deleteCloudEventState(_LocalEventState state) async {
    try {
      final deviceId = await _deviceId();
      final reference = _deviceDocument(state.uid, deviceId: deviceId)
          .collection('notificationEvents')
          .doc(hikeReminderEventDocumentId(state.eventKey));
      await reference.delete();
    } catch (error) {
      _recordDiagnostic('event_cleanup_deferred', {
        'classification': _classifyFailure(error).name,
      });
    }
  }

  Future<void> _handleInitialNotificationLaunch() async {
    final localLaunchFuture = () async {
      try {
        final launchDetails = await _localNotifications
            .getNotificationAppLaunchDetails()
            .timeout(_initializationTimeout);
        final response = launchDetails?.notificationResponse;
        if (launchDetails?.didNotificationLaunchApp == true &&
            response?.payload != null) {
          await _enqueuePayloadNavigation(response!.payload!);
        }
      } catch (error) {
        _recordDiagnostic('initial_local_tap_handling_failed', {
          'error': _safeErrorSummary(error),
          'classification': _classifyFailure(error).name,
        });
      }
    }();

    final remoteLaunchFuture = () async {
      try {
        final initialMessage = await _messaging.getInitialMessage().timeout(
          _initializationTimeout,
        );
        if (initialMessage != null) {
          await _handleRemoteNotificationTap(initialMessage);
        }
      } catch (error) {
        _recordDiagnostic('initial_remote_tap_handling_failed', {
          'error': _safeErrorSummary(error),
          'classification': _classifyFailure(error).name,
        });
      }
    }();

    await Future.wait<void>([localLaunchFuture, remoteLaunchFuture]);

    try {
      await _loadPreferences(reload: true);
      final pendingPayload = _preferences?.getString(pendingTapPreferenceKey);
      if (pendingPayload != null && pendingPayload.trim().isNotEmpty) {
        await _enqueuePayloadNavigation(pendingPayload);
      }
    } catch (error) {
      _recordDiagnostic('initial_tap_handling_failed', {
        'error': _safeErrorSummary(error),
      });
    }
  }

  Future<void> _handleRemoteNotificationTap(RemoteMessage message) async {
    final payload = HikeNotificationPayload.fromRemoteMessage(message);
    if (payload != null) {
      await _enqueuePayloadNavigation(payload.toJsonString());
    }
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.trim().isNotEmpty) {
      _startGuardedTask(
        'local_tap_handling_failed',
        () => _enqueuePayloadNavigation(payload),
      );
    }
  }

  Future<void> _enqueuePayloadNavigation(String rawPayload) async {
    final payload = HikeNotificationPayload.tryParse(rawPayload);
    if (payload == null) {
      await _clearPersistedTap();
      return;
    }

    await _loadPreferences(reload: true);
    final consumed =
        _preferences?.getBool(_consumedTapKey(payload.eventKey)) ?? false;
    if (consumed) {
      await _clearPersistedTap();
      return;
    }

    _pendingNavigationPayload = payload;
    _navigationRetryCount = 0;
    await _preferences?.setString(
      pendingTapPreferenceKey,
      payload.toJsonString(),
    );
    _schedulePendingNavigationAttempt();
  }

  void _schedulePendingNavigationAttempt() {
    if (_navigationAttemptScheduled ||
        _navigationInProgress ||
        _pendingNavigationPayload == null) {
      return;
    }

    _navigationAttemptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationAttemptScheduled = false;
      unawaited(_tryOpenPendingPayload());
    });
  }

  Future<void> _tryOpenPendingPayload() async {
    if (_navigationInProgress) {
      return;
    }
    final payload = _pendingNavigationPayload;
    if (payload == null) {
      return;
    }

    _navigationInProgress = true;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _scheduleNavigationRetry();
        return;
      }
      if (user.uid != payload.uid || payload.hikeDateKey != _currentDateKey()) {
        await _consumePendingTap(payload);
        return;
      }

      final deviceId = await _deviceId();
      if (payload.deviceId != deviceId) {
        await _consumePendingTap(payload);
        return;
      }

      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        _scheduleNavigationRetry();
        return;
      }

      final hike = await _loadExactHike(payload);
      if (hike == null ||
          ScheduledHike.dateKey(hike.hikeDate) != _currentDateKey()) {
        await _consumePendingTap(payload);
        return;
      }

      final route =
          hike.trailId.trim().isNotEmpty && hike.trailId != 'unknown-trail'
          ? AppRoutes.trail(hike.mountainId, hike.trailId)
          : AppRoutes.mountain(hike.mountainId);
      await _consumePendingTap(payload);
      if (appRouteObserver.currentRouteName != route) {
        unawaited(navigator.pushNamed(route));
      }
    } catch (error) {
      _recordDiagnostic('tap_navigation_deferred', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
      _scheduleNavigationRetry();
    } finally {
      _navigationInProgress = false;
    }
  }

  void _scheduleNavigationRetry() {
    if (_navigationRetryTimer?.isActive == true || _navigationRetryCount >= 5) {
      return;
    }
    _navigationRetryCount++;
    _navigationRetryTimer = Timer(const Duration(seconds: 1), () {
      _schedulePendingNavigationAttempt();
    });
  }

  Future<void> _consumePendingTap(HikeNotificationPayload payload) async {
    await _loadPreferences();
    await _preferences?.setBool(_consumedTapKey(payload.eventKey), true);
    await _clearPersistedTap();
    _pendingNavigationPayload = null;
    _navigationRetryTimer?.cancel();
  }

  Future<void> _clearPersistedTap() async {
    await _loadPreferences();
    await _preferences?.remove(pendingTapPreferenceKey);
  }

  String _consumedTapKey(String eventKey) {
    return '$_consumedTapPrefix${hikeReminderEventDocumentId(eventKey)}';
  }

  Future<ScheduledHike?> _loadExactHike(HikeNotificationPayload payload) async {
    try {
      final document = await _firestore
          .collection('users')
          .doc(payload.uid)
          .collection('scheduled_hikes')
          .doc(payload.hikeId)
          .get();
      if (!document.exists || document.data() == null) {
        return null;
      }
      final hike = ScheduledHike.fromFirestore(
        documentId: document.id,
        data: document.data()!,
        ownerUid: payload.uid,
      );
      if (hike.id != payload.hikeId ||
          ScheduledHike.dateKey(hike.hikeDate) != payload.hikeDateKey) {
        return null;
      }
      return hike;
    } catch (error) {
      _recordDiagnostic('hike_validation_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
      throw NotificationServiceException(
        message: _safeErrorSummary(error),
        kind: _classifyFailure(error),
        operation: 'hike-validation',
      );
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    final previousUid = _activeUid;
    final nextUid = user?.uid;
    if (previousUid == nextUid) {
      return;
    }

    if (previousUid != null) {
      await _cancelAllHikeNotificationsInternal(uid: previousUid);
      await _disableCloudDevice(previousUid);
    }

    _activeUid = nextUid;
    if (nextUid == null) {
      _setEffectiveEnabled(false);
      await _syncTokenRefreshSubscription();
      return;
    }

    await _requestReconciliation();
    await _syncTokenRefreshSubscription();
    _navigationRetryCount = 0;
    _schedulePendingNavigationAttempt();
  }

  Future<void> _handleTokenRefresh(String token) async {
    await _loadPreferences(reload: true);
    final enabledPreference =
        _preferences?.getBool(_enabledPreferenceKey) ?? false;
    if (!enabledPreference || _auth.currentUser == null) {
      return;
    }

    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      _recordDiagnostic('token_refresh_skipped', {'reason': 'empty-token'});
      return;
    }

    try {
      await _registerCurrentDevice(tokenOverride: trimmedToken, force: true);
    } catch (error) {
      _recordDiagnostic('token_refresh_registration_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
    }
  }

  Future<void> _restoreAfterDisableFailure({
    required String? uid,
    required bool previousPreference,
    required bool previousEffectiveState,
    required bool previousChannelBlocked,
  }) async {
    final preferenceRestored = await _setEnabledPreference(previousPreference);
    if (!preferenceRestored) {
      _recordDiagnostic('disable_rollback_preference_failed');
    }

    _channelBlocked = previousChannelBlocked;
    _setEffectiveEnabled(previousEffectiveState);
    await _syncTokenRefreshSubscription();

    if (uid == null || !previousPreference || previousChannelBlocked) {
      return;
    }

    try {
      await _registerCurrentDevice(force: true);
      await _reconcileScheduledHikesForUser(uid);
    } catch (error) {
      _recordDiagnostic('disable_rollback_reschedule_deferred', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
    }
  }

  Future<void> _applyExplicitSystemDisable(String uid) async {
    await _setEnabledPreference(false);
    _channelBlocked = false;
    _setEffectiveEnabled(false);
    await _cancelAllHikeNotificationsInternal(uid: uid);
    await _disableCloudDevice(uid);
    await _deleteFcmTokenQuietly();
    await _setAutoInitEnabledPreservingState(false);
    await _syncTokenRefreshSubscription();
  }

  Future<_NotificationPermissionResult> _requestSystemPermission() async {
    if (kIsWeb) {
      return _NotificationPermissionResult.unsupported();
    }

    try {
      await _ensureLocalNotificationsReady();
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        return _darwinPermissionResult(settings.authorizationStatus);
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _androidPlugin;
        final before = await androidPlugin?.areNotificationsEnabled();
        bool? requestResult;
        if (before != true) {
          requestResult = await androidPlugin
              ?.requestNotificationsPermission()
              .timeout(_initializationTimeout);
        }
        final after = await androidPlugin?.areNotificationsEnabled();
        if (after == false) {
          return _NotificationPermissionResult.appDisabled(
            androidRequestStatus: _nullablePermissionStatus(requestResult),
          );
        }
        if (after != true) {
          return _NotificationPermissionResult.temporary(
            'SummitTrack could not confirm Android notification permission.',
            androidRequestStatus: _nullablePermissionStatus(requestResult),
          );
        }
        final channel = await _validateAndroidChannel();
        if (!channel.allowed) {
          return channel;
        }
        return _NotificationPermissionResult.allowed(
          osStatus: 'allowed',
          firebaseMessagingStatus: await _androidMessagingStatus(true),
          channelStatus: channel.channelStatus,
          androidRequestStatus: _nullablePermissionStatus(requestResult),
        );
      }
    } catch (error) {
      return _NotificationPermissionResult.temporary(
        'SummitTrack could not request notification permission '
        '(${_safeErrorSummary(error)}).',
      );
    }
    return _NotificationPermissionResult.unsupported();
  }

  Future<_NotificationPermissionResult> _checkSystemPermission() async {
    if (kIsWeb) {
      return _NotificationPermissionResult.unsupported();
    }

    try {
      await _ensureLocalNotificationsReady();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final enabled = await _androidPlugin?.areNotificationsEnabled().timeout(
          _initializationTimeout,
        );
        if (enabled == false) {
          return _NotificationPermissionResult.appDisabled();
        }
        if (enabled != true) {
          return _NotificationPermissionResult.temporary(
            'SummitTrack could not confirm Android notification permission.',
          );
        }
        final channel = await _validateAndroidChannel();
        if (!channel.allowed) {
          return channel;
        }
        return _NotificationPermissionResult.allowed(
          osStatus: 'allowed',
          firebaseMessagingStatus: await _androidMessagingStatus(true),
          channelStatus: channel.channelStatus,
        );
      }

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final settings = await _messaging.getNotificationSettings().timeout(
          _initializationTimeout,
        );
        return _darwinPermissionResult(settings.authorizationStatus);
      }
    } catch (error) {
      return _NotificationPermissionResult.temporary(
        'SummitTrack could not check notification permission '
        '(${_safeErrorSummary(error)}).',
      );
    }
    return _NotificationPermissionResult.unsupported();
  }

  Future<_NotificationPermissionResult> _validateAndroidChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android || kIsWeb) {
      return _NotificationPermissionResult.allowed(
        osStatus: 'not-android',
        firebaseMessagingStatus: 'not-android',
        channelStatus: 'not-android',
      );
    }

    try {
      final channels = await _androidPlugin?.getNotificationChannels().timeout(
        _initializationTimeout,
      );
      if (channels == null) {
        return _NotificationPermissionResult.temporary(
          'SummitTrack could not inspect the Hike Reminders channel.',
          channelStatus: 'unknown',
        );
      }
      AndroidNotificationChannel? target;
      for (final channel in channels) {
        if (channel.id == channelId) {
          target = channel;
          break;
        }
      }
      if (target == null) {
        return _NotificationPermissionResult.temporary(
          'The Android Hike Reminders channel has not been created yet.',
          channelStatus: 'missing',
        );
      }
      if (target.importance == Importance.none) {
        return _NotificationPermissionResult.channelDisabled();
      }
      return _NotificationPermissionResult.allowed(
        osStatus: 'allowed',
        firebaseMessagingStatus: 'unknown',
        channelStatus: target.importance.name,
      );
    } catch (error) {
      return _NotificationPermissionResult.temporary(
        'SummitTrack could not inspect the Hike Reminders channel '
        '(${_safeErrorSummary(error)}).',
        channelStatus: 'error',
      );
    }
  }

  _NotificationPermissionResult _darwinPermissionResult(
    AuthorizationStatus status,
  ) {
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      return _NotificationPermissionResult.allowed(
        osStatus: _authorizationStatusName(status),
        firebaseMessagingStatus: _authorizationStatusName(status),
        channelStatus: 'not-applicable',
      );
    }
    if (status == AuthorizationStatus.denied) {
      return _NotificationPermissionResult.appDisabled(
        message: 'Notification permission was denied in system settings.',
      );
    }
    return _NotificationPermissionResult.temporary(
      'Notification permission has not been decided yet.',
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    return _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  Future<String> _androidMessagingStatus(bool notificationsAllowed) async {
    try {
      final settings = await _messaging.getNotificationSettings();
      final status = _authorizationStatusName(settings.authorizationStatus);
      if (notificationsAllowed &&
          settings.authorizationStatus != AuthorizationStatus.authorized) {
        return '$status->authorized(android-system-allowed)';
      }
      return status;
    } catch (_) {
      return notificationsAllowed
          ? 'authorized(android-system-allowed)'
          : 'unknown';
    }
  }

  Future<void> _registerCurrentDevice({
    String? tokenOverride,
    bool force = false,
  }) async {
    final running = _registrationFuture;
    if (running != null) {
      await running;
      if (tokenOverride?.trim().isNotEmpty == true) {
        await _registerCurrentDevice(tokenOverride: tokenOverride, force: true);
      }
      return;
    }

    late final Future<void> sharedFuture;
    sharedFuture =
        _registerCurrentDeviceOnce(
          tokenOverride: tokenOverride,
          force: force,
        ).whenComplete(() {
          if (identical(_registrationFuture, sharedFuture)) {
            _registrationFuture = null;
          }
        });
    _registrationFuture = sharedFuture;
    await sharedFuture;
  }

  Future<void> _registerCurrentDeviceOnce({
    String? tokenOverride,
    required bool force,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const NotificationServiceException(
        message: 'Please sign in before enabling hike notifications.',
        kind: NotificationFailureKind.userAction,
        operation: 'device-registration',
      );
    }
    if (!await _tryResolveTimeZone()) {
      throw const NotificationServiceException(
        message: 'The device timezone is temporarily unavailable.',
        kind: NotificationFailureKind.temporary,
        operation: 'device-registration',
      );
    }

    final deviceId = await _deviceId();
    await _messaging.setAutoInitEnabled(true).timeout(_initializationTimeout);
    final token =
        tokenOverride?.trim() ??
        (await _messaging.getToken().timeout(_initializationTimeout))?.trim() ??
        '';
    _recordDiagnostic('fcm_token_result', {
      'tokenReceived': token.isNotEmpty,
      'installation': _safeIdentifier(deviceId),
    });
    if (token.isEmpty) {
      throw const NotificationServiceException(
        message: 'Firebase did not return a notification token yet.',
        kind: NotificationFailureKind.temporary,
        operation: 'device-registration',
      );
    }

    final reference = _deviceDocument(user.uid, deviceId: deviceId);
    if (!force) {
      try {
        final existing = await reference.get();
        final data = existing.data();
        final updatedAt = data?['updatedAt'];
        final isFresh =
            updatedAt is Timestamp &&
            DateTime.now().difference(updatedAt.toDate()) <
                _registrationRefreshInterval;
        if (data?['fcmToken'] == token &&
            data?['notificationsEnabled'] == true &&
            data?['platform'] == _platformName() &&
            data?['timezone'] == _timeZoneName &&
            data?['appVersion'] == _appVersion &&
            data?['buildNumber'] == _buildNumber &&
            isFresh) {
          _recordDiagnostic('device_registration_skipped', {
            'reason': 'fresh-existing-record',
          });
          return;
        }
      } catch (error) {
        _recordDiagnostic('device_registration_read_failed', {
          'classification': _classifyFailure(error).name,
        });
      }
    }

    _recordDiagnostic('device_registration_started', {
      'platform': _platformName(),
      'tokenReceived': true,
      'installation': _safeIdentifier(deviceId),
    });
    await reference.set({
      'fcmToken': token,
      'notificationsEnabled': true,
      'platform': _platformName(),
      'timezone': _timeZoneName,
      'appVersion': _appVersion,
      'buildNumber': _buildNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _recordDiagnostic('device_registration_succeeded', {
      'platform': _platformName(),
    });

    await _disableDuplicateAndroidRegistrations(
      uid: user.uid,
      currentDeviceId: deviceId,
      fcmToken: token,
    );
  }

  Future<void> _disableCloudDevice(
    String uid, {
    bool throwOnFailure = false,
  }) async {
    try {
      final deviceId = await _deviceId();
      await _deviceDocument(uid, deviceId: deviceId).set({
        'platform': _platformName(),
        'notificationsEnabled': false,
        'timezone': _timeZoneResolved ? _timeZoneName : 'unresolved',
        'appVersion': _appVersion,
        'buildNumber': _buildNumber,
        'updatedAt': FieldValue.serverTimestamp(),
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      _recordDiagnostic('device_disable_succeeded');
    } catch (error) {
      _recordDiagnostic('device_disable_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
      if (throwOnFailure) {
        throw NotificationServiceException(
          message: _cloudDisableFailureMessage(error),
          kind: _classifyFailure(error),
          operation: 'device-disable',
        );
      }
    }
  }

  DocumentReference<Map<String, dynamic>> _deviceDocument(
    String uid, {
    required String deviceId,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId);
  }

  Future<void> _disableDuplicateAndroidRegistrations({
    required String uid,
    required String currentDeviceId,
    required String fcmToken,
  }) async {
    if (_platformName() != 'android') {
      return;
    }

    try {
      final matches = await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .where('fcmToken', isEqualTo: fcmToken)
          .get();
      final batch = _firestore.batch();
      var duplicateCount = 0;
      for (final document in matches.docs) {
        final data = document.data();
        if (document.id == currentDeviceId || data['platform'] != 'android') {
          continue;
        }
        batch.set(document.reference, {
          'platform': 'android',
          'notificationsEnabled': false,
          'timezone': _timeZoneName,
          'appVersion': data['appVersion']?.toString() ?? _appVersion,
          'buildNumber': data['buildNumber']?.toString() ?? _buildNumber,
          'updatedAt': FieldValue.serverTimestamp(),
          'fcmToken': FieldValue.delete(),
        }, SetOptions(merge: true));
        duplicateCount++;
      }
      if (duplicateCount > 0) {
        await batch.commit();
      }
      _recordDiagnostic('duplicate_registration_cleanup_completed', {
        'duplicatesDisabled': duplicateCount,
      });
    } catch (error) {
      _recordDiagnostic('duplicate_registration_cleanup_deferred', {
        'classification': _classifyFailure(error).name,
      });
    }
  }

  Future<void> _reconcileScheduledHikesForUser(String uid) async {
    try {
      await HikeScheduleStore.instance.load();
      final hikes = HikeScheduleStore.instance.scheduledHikes
          .where((hike) => hike.ownerUid == null || hike.ownerUid == uid)
          .toList();
      await _reconcileScheduledHikesInternal(uid, hikes);
    } catch (error) {
      _recordDiagnostic('hike_reconciliation_failed', {
        'classification': _classifyFailure(error).name,
        'error': _safeErrorSummary(error),
      });
    }
  }

  Future<void> _syncTokenRefreshSubscription() async {
    final shouldListen =
        _userEnabledPreference && _auth.currentUser != null && !_channelBlocked;
    if (shouldListen) {
      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
        _startGuardedTask(
          'token_refresh_handling_failed',
          () => _handleTokenRefresh(token),
        );
      });
      return;
    }

    final subscription = _tokenRefreshSubscription;
    if (subscription != null) {
      _tokenRefreshSubscription = null;
      await subscription.cancel();
    }
  }

  Future<void> _deleteFcmTokenQuietly() async {
    try {
      await _messaging.deleteToken().timeout(_initializationTimeout);
    } catch (error) {
      _recordDiagnostic('token_delete_failed', {
        'classification': _classifyFailure(error).name,
      });
    }
  }

  Future<void> _setAutoInitEnabledPreservingState(bool enabled) async {
    try {
      await _messaging
          .setAutoInitEnabled(enabled)
          .timeout(_initializationTimeout);
    } catch (error) {
      _recordDiagnostic('messaging_auto_init_update_failed', {
        'requested': enabled,
        'classification': _classifyFailure(error).name,
      });
      if (enabled) {
        throw NotificationServiceException(
          message: 'Firebase Messaging auto-initialization is unavailable.',
          kind: _classifyFailure(error),
          operation: 'messaging-auto-init',
        );
      }
    }
  }

  Future<bool> _setEnabledPreference(bool enabled) async {
    await _loadPreferences();
    final preferences = _preferences;
    if (preferences == null) {
      return false;
    }

    final previous = _userEnabledPreference;
    try {
      final saved = await preferences.setBool(_enabledPreferenceKey, enabled);
      if (saved) {
        _userEnabledPreference = enabled;
      } else {
        _userEnabledPreference = previous;
      }
      return saved;
    } catch (error) {
      _userEnabledPreference = previous;
      _recordDiagnostic('preference_save_failed', {
        'classification': _classifyFailure(error).name,
      });
      return false;
    }
  }

  void _setEffectiveEnabled(bool enabled) {
    if (_effectiveEnabled == enabled) {
      return;
    }
    _effectiveEnabled = enabled;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> _tryResolveTimeZone() {
    if (_timeZoneResolved) {
      return SynchronousFuture<bool>(true);
    }
    final running = _timeZoneFuture;
    if (running != null) {
      return running;
    }

    late final Future<bool> sharedFuture;
    sharedFuture = _resolveTimeZone().whenComplete(() {
      if (!_timeZoneResolved && identical(_timeZoneFuture, sharedFuture)) {
        _timeZoneFuture = null;
      }
    });
    _timeZoneFuture = sharedFuture;
    return sharedFuture;
  }

  Future<bool> _resolveTimeZone() async {
    try {
      tz_data.initializeTimeZones();
      final resolved = (await FlutterTimezone.getLocalTimezone()).trim();
      if (resolved.isEmpty) {
        throw StateError('empty-timezone');
      }
      tz.setLocalLocation(tz.getLocation(resolved));
      _timeZoneName = resolved;
      _timeZoneResolved = true;
      _recordDiagnostic('timezone_resolved', {'timezone': resolved});
      return true;
    } catch (error) {
      _timeZoneName = 'unresolved';
      _timeZoneResolved = false;
      _recordDiagnostic('timezone_resolution_failed', {
        'error': _safeErrorSummary(error),
        'classification': NotificationFailureKind.temporary.name,
      });
      return false;
    }
  }

  Future<void> _ensureLocalNotificationsReady() {
    if (_localNotificationsInitialized) {
      return SynchronousFuture<void>(null);
    }
    final running = _localInitializationFuture;
    if (running != null) {
      return running;
    }

    late final Future<void> sharedFuture;
    sharedFuture = _initializeLocalNotifications().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      if (identical(_localInitializationFuture, sharedFuture)) {
        _localInitializationFuture = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _localInitializationFuture = sharedFuture;
    return sharedFuture;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      androidNotificationIcon,
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    _recordDiagnostic('local_plugin_initialization_started');
    try {
      final initialized = await _localNotifications
          .initialize(
            settings,
            onDidReceiveNotificationResponse: _handleLocalNotificationTap,
            onDidReceiveBackgroundNotificationResponse:
                summitTrackLocalNotificationBackgroundTap,
          )
          .timeout(_initializationTimeout);
      if (initialized == false) {
        throw StateError('plugin-returned-false');
      }
      await _createAndroidNotificationChannel();
      _localNotificationsInitialized = true;
      _recordDiagnostic('local_plugin_initialization_succeeded');
    } catch (error) {
      _localNotificationsInitialized = false;
      throw NotificationServiceException(
        message: _safeErrorSummary(error),
        kind: _classifyFailure(error),
        operation: 'local-plugin-initialization',
      );
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );
    final plugin = _androidPlugin;
    if (plugin == null) {
      throw const NotificationServiceException(
        message: 'The Android notification implementation is unavailable.',
        kind: NotificationFailureKind.temporary,
        operation: 'channel-creation',
      );
    }
    _recordDiagnostic('notification_channel_creation_started', {
      'channel': channelId,
    });
    await plugin
        .createNotificationChannel(channel)
        .timeout(_initializationTimeout);
    _recordDiagnostic('notification_channel_created', {'channel': channelId});
  }

  NotificationDetails _notificationDetails({
    required String hikeId,
    required Duration timeoutAfter,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        icon: androidNotificationIcon,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        timeoutAfter: max(1000, timeoutAfter.inMilliseconds),
        tag: 'hike_$hikeId',
        autoCancel: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  HikeNotificationPayload _payloadForHike({
    required String uid,
    required ScheduledHike hike,
    required String deviceId,
  }) {
    final hikeDateKey = ScheduledHike.dateKey(hike.hikeDate);
    final eventKey = buildHikeReminderEventKey(
      uid: uid,
      hikeId: hike.id,
      hikeDateKey: hikeDateKey,
      deviceId: deviceId,
    );
    return HikeNotificationPayload(
      type: notificationType,
      uid: uid,
      hikeId: hike.id,
      hikeDateKey: hikeDateKey,
      mountainId: hike.mountainId,
      mountainName: _safeMountainName(hike.mountainName),
      deviceId: deviceId,
      eventKey: eventKey,
    );
  }

  tz.TZDateTime _scheduledDateFor(DateTime hikeDate) {
    final date = ScheduledHike.dateOnly(hikeDate);
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      _internalReminderHour,
      _internalReminderMinute,
    );
  }

  Duration _expirationAfterPosting(tz.TZDateTime scheduledDate) {
    final nextMidnight = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day + 1,
    );
    final duration = nextMidnight.difference(scheduledDate);
    return duration.isNegative ? Duration.zero : duration;
  }

  Duration _timeoutUntilNextLocalDay() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    return duration.isNegative ? Duration.zero : duration;
  }

  DateTime _nextLocalMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime _midnightAfterDateKey(String dateKey) {
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) {
      return _nextLocalMidnight();
    }
    return DateTime(parsed.year, parsed.month, parsed.day + 1);
  }

  String _currentDateKey() {
    final key = ScheduledHike.dateKey(DateTime.now());
    _recordDiagnostic('current_date_key', {'currentDateKey': key});
    return key;
  }

  bool _isTodayOrFuture(DateTime date) {
    final today = ScheduledHike.dateOnly(DateTime.now());
    return !ScheduledHike.dateOnly(date).isBefore(today);
  }

  bool _isExpired(String hikeDateKey) {
    return hikeDateKey.compareTo(_currentDateKey()) < 0;
  }

  Future<int> _notificationIdFor({
    required String uid,
    required String hikeId,
  }) async {
    final map = await _readNotificationIdMap();
    final key = _mappingKey(uid, hikeId);
    final existing = map[key];
    if (existing != null) {
      return existing;
    }

    final used = map.entries
        .where((entry) => entry.key != key)
        .map((entry) => entry.value)
        .toSet();
    var attempt = 0;
    var candidate = _stableNotificationId('$uid|$hikeId');
    while (used.contains(candidate)) {
      attempt++;
      candidate = _stableNotificationId('$uid|$hikeId|$attempt');
    }
    map[key] = candidate;
    await _writeNotificationIdMap(map);
    _recordDiagnostic('notification_id_resolved', {
      'notificationId': candidate,
    });
    return candidate;
  }

  int _stableNotificationId(String value) {
    const fnvPrime = 16777619;
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    final id = hash & _maximumNotificationId;
    return id == 0 ? 1 : id;
  }

  Future<Map<(String, String), int>> _knownNotificationIds({
    String? uid,
  }) async {
    final map = await _readNotificationIdMap();
    final values = <(String, String), int>{};
    for (final entry in map.entries) {
      final parts = _splitMappingKey(entry.key);
      if (parts == null || uid != null && parts.$1 != uid) {
        continue;
      }
      values[parts] = entry.value;
    }
    return values;
  }

  Future<Map<String, int>> _readNotificationIdMap() async {
    await _loadPreferences();
    final raw = _preferences?.getString(_notificationIdsPreferenceKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, int>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, int>{};
      }
      return decoded.map((key, value) {
        return MapEntry(key.toString(), value is int ? value : 0);
      })..removeWhere((_, value) => value <= 0);
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _writeNotificationIdMap(Map<String, int> map) async {
    await _loadPreferences();
    await _preferences?.setString(
      _notificationIdsPreferenceKey,
      jsonEncode(map),
    );
  }

  Future<void> _cancelUnknownAccountNotifications(
    String uid,
    Set<String> validMappingKeys,
  ) async {
    final map = await _readNotificationIdMap();
    for (final entry in map.entries) {
      final parts = _splitMappingKey(entry.key);
      if (parts == null ||
          parts.$1 != uid ||
          validMappingKeys.contains(entry.key)) {
        continue;
      }
      await _cancelHikeNotificationInternal(uid: uid, hikeId: parts.$2);
    }
  }

  Future<void> _cancelNotificationId(int id, {String? hikeId}) async {
    if (!_localNotificationsInitialized) {
      return;
    }
    if (hikeId != null && hikeId.trim().isNotEmpty) {
      await _localNotifications.cancel(id, tag: 'hike_$hikeId');
    }
    await _localNotifications.cancel(id);
  }

  Future<bool> _pendingRequestExists(int notificationId) async {
    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      return pending.any((request) => request.id == notificationId);
    } catch (error) {
      _recordDiagnostic('pending_request_check_failed', {
        'notificationId': notificationId,
        'error': _safeErrorSummary(error),
      });
      return false;
    }
  }

  Future<_LocalEventState?> _readLocalEventState(String eventKey) async {
    await _loadPreferences(reload: true);
    final raw = _preferences?.getString(_localEventPreferenceKey(eventKey));
    return _LocalEventState.tryParse(raw);
  }

  Future<List<_LocalEventState>> _readLocalEventStates({
    String? uid,
    String? hikeId,
  }) async {
    await _loadPreferences(reload: true);
    final states = <_LocalEventState>[];
    final keys = _preferences?.getKeys() ?? const <String>{};
    for (final key in keys) {
      if (!key.startsWith(_localEventStatePrefix)) {
        continue;
      }
      final state = _LocalEventState.tryParse(_preferences?.getString(key));
      if (state == null ||
          uid != null && state.uid != uid ||
          hikeId != null && state.hikeId != hikeId) {
        continue;
      }
      states.add(state);
    }
    return states;
  }

  Future<bool> _writeLocalEventState(_LocalEventState state) async {
    await _loadPreferences();
    try {
      return await _preferences?.setString(
            _localEventPreferenceKey(state.eventKey),
            state.toJsonString(),
          ) ??
          false;
    } catch (error) {
      _recordDiagnostic('local_event_state_write_failed', {
        'classification': _classifyFailure(error).name,
      });
      return false;
    }
  }

  Future<void> _removeLocalEventState(String eventKey) async {
    await _loadPreferences();
    await _preferences?.remove(_localEventPreferenceKey(eventKey));
  }

  String _localEventPreferenceKey(String eventKey) {
    return '$_localEventStatePrefix${hikeReminderEventDocumentId(eventKey)}';
  }

  String _mappingKey(String uid, String hikeId) => '$uid|$hikeId';

  (String, String)? _splitMappingKey(String value) {
    final separator = value.indexOf('|');
    if (separator <= 0 || separator == value.length - 1) {
      return null;
    }
    return (value.substring(0, separator), value.substring(separator + 1));
  }

  Future<void> _loadPreferences({bool reload = false}) async {
    _preferences ??= await SharedPreferences.getInstance().timeout(
      _initializationTimeout,
    );
    if (reload) {
      await _preferences?.reload().timeout(_initializationTimeout);
    }
  }

  Future<String> _deviceId() async {
    await _loadPreferences();
    final preferences = _preferences;
    final stored = preferences?.getString(_deviceIdPreferenceKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final saved =
        await preferences?.setString(_deviceIdPreferenceKey, id) ?? false;
    if (!saved) {
      throw const NotificationServiceException(
        message: 'The installation identifier could not be persisted.',
        kind: NotificationFailureKind.temporary,
        operation: 'installation-identity',
      );
    }
    return id;
  }

  Future<User?> _currentUserAfterRestore() async {
    final current = _auth.currentUser;
    if (current != null) {
      return current;
    }
    try {
      return await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  String _notificationTitle() => 'Hike day na! 🥾';

  String _notificationBody({
    required String firstName,
    required String mountainName,
  }) {
    return 'Good morning, $firstName! May scheduled hike ka today sa '
        '${_safeMountainName(mountainName)}. Check your gear, weather, and '
        'route bago umalis.';
  }

  String _firstName(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }
    return 'Hiker';
  }

  String _safeMountainName(String? mountainName) {
    final value = mountainName?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'unknown') {
      return 'your scheduled mountain';
    }
    return value;
  }

  NotificationFailureKind _classifyFailure(Object error) {
    if (error is NotificationServiceException) {
      return error.kind;
    }
    if (error is TimeoutException) {
      return NotificationFailureKind.temporary;
    }
    if (error is FirebaseException) {
      const temporaryCodes = <String>{
        'aborted',
        'cancelled',
        'deadline-exceeded',
        'internal',
        'network-request-failed',
        'resource-exhausted',
        'too-many-requests',
        'unavailable',
        'unknown',
      };
      if (temporaryCodes.contains(error.code)) {
        return NotificationFailureKind.temporary;
      }
      if (error.code == 'permission-denied' ||
          error.code == 'unauthenticated') {
        return NotificationFailureKind.permanent;
      }
    }
    if (error is MissingPluginException || error is PlatformException) {
      return NotificationFailureKind.temporary;
    }
    return NotificationFailureKind.temporary;
  }

  String _safeErrorSummary(Object error) {
    if (error is NotificationServiceException) {
      return '${error.operation}:${error.kind.name}';
    }
    if (error is FirebaseException) {
      return '${error.plugin}:${error.code}';
    }
    if (error is PlatformException) {
      return 'platform:${error.code}';
    }
    if (error is TimeoutException) {
      return 'timeout';
    }
    return error.runtimeType.toString();
  }

  String _registrationFailureMessage(Object error) {
    if (error is NotificationServiceException) {
      return error.message;
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firestore denied writing this device registration.';
      }
      if (_classifyFailure(error) == NotificationFailureKind.temporary) {
        return 'Device registration is temporarily unavailable. Your prior '
            'notification state was preserved.';
      }
      return 'SummitTrack could not save this device registration '
          '(Firestore ${error.code}).';
    }
    return 'Device registration is temporarily unavailable. Your prior '
        'notification state was preserved.';
  }

  String _disableFailureMessage(Object error) {
    if (error is NotificationServiceException) {
      return error.message;
    }
    return 'SummitTrack could not turn off hike reminders. Please try again.';
  }

  String _cloudDisableFailureMessage(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Firestore denied updating this device notification setting.';
    }
    return 'SummitTrack could not update this device notification setting. '
        'Please try again.';
  }

  String _authorizationStatusName(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => 'authorized',
      AuthorizationStatus.denied => 'denied',
      AuthorizationStatus.notDetermined => 'not-determined',
      AuthorizationStatus.provisional => 'provisional',
    };
  }

  String _nullablePermissionStatus(bool? value) {
    return switch (value) {
      true => 'allowed',
      false => 'blocked',
      null => 'not-returned',
    };
  }

  String _safeIdentifier(String value) {
    final digest = sha256.convert(utf8.encode(value)).toString();
    return digest.substring(0, 10);
  }

  void _recordPermissionDiagnostic(
    String event,
    _NotificationPermissionResult permission,
  ) {
    _recordDiagnostic(event, {
      'osPermission': permission.osStatus,
      'firebaseMessaging': permission.firebaseMessagingStatus,
      'channel': permission.channelStatus,
      'androidRequest': permission.androidRequestStatus,
      'classification': permission.failureKind.name,
    });
  }

  void _recordDiagnostic(
    String event, [
    Map<String, Object?> fields = const <String, Object?>{},
  ]) {
    if (!notificationDiagnostics && !kDebugMode) {
      return;
    }
    final values = fields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    final line = values.isEmpty ? event : '$event $values';
    if (notificationDiagnostics) {
      _diagnosticEntries.add(line);
      if (_diagnosticEntries.length > 120) {
        _diagnosticEntries.removeAt(0);
      }
    }
    debugPrint('[HikeNotifications] $line');
  }

  void _startGuardedTask(String failureEvent, Future<void> Function() task) {
    unawaited(_runGuardedTask(failureEvent, task));
  }

  Future<void> _runGuardedTask(
    String failureEvent,
    Future<void> Function() task,
  ) async {
    try {
      await task();
    } catch (error) {
      _recordDiagnostic(failureEvent, {
        'error': _safeErrorSummary(error),
        'classification': _classifyFailure(error).name,
      });
    }
  }

  Future<NotificationDiagnosticsReport> collectDiagnostics() async {
    if (!notificationDiagnostics) {
      return const NotificationDiagnosticsReport(
        summary: 'Notification diagnostics are disabled in this build.',
        openSettingsSuggested: false,
      );
    }

    try {
      await initialize();
    } catch (error) {
      _recordDiagnostic('diagnostic_initialization_failed', {
        'error': _safeErrorSummary(error),
      });
    }
    await _tryResolveTimeZone();
    final permission = await _checkSystemPermission();
    _recordPermissionDiagnostic('diagnostic_permission_result', permission);
    var pendingCount = -1;
    try {
      pendingCount =
          (await _localNotifications.pendingNotificationRequests()).length;
    } catch (error) {
      _recordDiagnostic('diagnostic_pending_read_failed', {
        'error': _safeErrorSummary(error),
      });
    }

    final header = <String>[
      'timezone=$_timeZoneName',
      'currentDateKey=${_currentDateKey()}',
      'permission=${permission.osStatus}',
      'channel=${permission.channelStatus}',
      'pendingCount=$pendingCount',
      'enabledPreference=$_userEnabledPreference',
      'effectiveEnabled=$_effectiveEnabled',
    ];
    return NotificationDiagnosticsReport(
      summary: [...header, ..._diagnosticEntries].join('\n'),
      openSettingsSuggested: permission.openSettingsSuggested,
    );
  }

  Future<HikeReminderResult> runProductionDiagnosticShow() async {
    if (!notificationDiagnostics) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'Notification diagnostics are disabled.',
      );
    }
    try {
      await initialize();
      final permission = await _checkSystemPermission();
      _recordPermissionDiagnostic('diagnostic_show_permission', permission);
      if (!permission.allowed) {
        return HikeReminderResult(
          status: HikeReminderStatus.permanentFailure,
          message: permission.message,
        );
      }
      final id = _stableNotificationId('summittrack-production-diagnostic');
      _recordDiagnostic('show_started', {
        'notificationId': id,
        'source': 'diagnostic',
      });
      await _showNotification(
        id: id,
        title: 'SummitTrack notification test',
        body: 'The production Hike Reminders channel and icon are working.',
        hikeId: 'diagnostic',
        payload: jsonEncode({
          'type': 'notification_diagnostic',
          'hikeDateKey': _currentDateKey(),
        }),
      );
      _recordDiagnostic('show_succeeded', {
        'notificationId': id,
        'source': 'diagnostic',
      });
      return HikeReminderResult(
        status: HikeReminderStatus.shown,
        message: 'The production notification test was displayed.',
        notificationId: id,
      );
    } catch (error) {
      _recordDiagnostic('show_failed', {
        'source': 'diagnostic',
        'error': _safeErrorSummary(error),
      });
      return HikeReminderResult(
        status: HikeReminderStatus.retryableFailure,
        message:
            'The production notification test failed: '
            '${_safeErrorSummary(error)}',
      );
    }
  }

  Future<bool> openNotificationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _settingsChannel.invokeMethod<bool>(
            'openNotificationSettings',
          ) ??
          false;
    } catch (error) {
      _recordDiagnostic('open_notification_settings_failed', {
        'error': _safeErrorSummary(error),
      });
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listenersInstalled) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _navigationRetryTimer?.cancel();
    unawaited(_authSubscription?.cancel());
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_foregroundMessageSubscription?.cancel());
    unawaited(_messageOpenedSubscription?.cancel());
    super.dispose();
  }
}

@immutable
class NotificationEnableResult {
  const NotificationEnableResult.success(this.message)
    : enabled = true,
      failureKind = null,
      openSettingsSuggested = false;

  const NotificationEnableResult.failure(
    this.message, {
    required this.failureKind,
    this.openSettingsSuggested = false,
  }) : enabled = false;

  final bool enabled;
  final String message;
  final NotificationFailureKind? failureKind;
  final bool openSettingsSuggested;
}

@immutable
class NotificationDisableResult {
  const NotificationDisableResult.success(this.message) : disabled = true;

  const NotificationDisableResult.failure(this.message) : disabled = false;

  final bool disabled;
  final String message;
}

@immutable
class NotificationDiagnosticsReport {
  const NotificationDiagnosticsReport({
    required this.summary,
    required this.openSettingsSuggested,
  });

  final String summary;
  final bool openSettingsSuggested;
}

class _NotificationPermissionResult {
  const _NotificationPermissionResult({
    required this.allowed,
    required this.failureKind,
    required this.message,
    required this.osStatus,
    required this.firebaseMessagingStatus,
    required this.channelStatus,
    this.androidRequestStatus = 'not-requested',
    this.appNotificationsExplicitlyDisabled = false,
    this.channelBlocked = false,
    this.openSettingsSuggested = false,
  });

  factory _NotificationPermissionResult.allowed({
    required String osStatus,
    required String firebaseMessagingStatus,
    required String channelStatus,
    String androidRequestStatus = 'not-requested',
  }) {
    return _NotificationPermissionResult(
      allowed: true,
      failureKind: NotificationFailureKind.none,
      message: 'Notifications are allowed.',
      osStatus: osStatus,
      firebaseMessagingStatus: firebaseMessagingStatus,
      channelStatus: channelStatus,
      androidRequestStatus: androidRequestStatus,
    );
  }

  factory _NotificationPermissionResult.appDisabled({
    String message =
        'Android system notifications are turned off for SummitTrack.',
    String androidRequestStatus = 'not-requested',
  }) {
    return _NotificationPermissionResult(
      allowed: false,
      failureKind: NotificationFailureKind.permanent,
      message: message,
      osStatus: 'blocked',
      firebaseMessagingStatus: 'denied',
      channelStatus: 'unavailable',
      androidRequestStatus: androidRequestStatus,
      appNotificationsExplicitlyDisabled: true,
      openSettingsSuggested: true,
    );
  }

  factory _NotificationPermissionResult.channelDisabled() {
    return const _NotificationPermissionResult(
      allowed: false,
      failureKind: NotificationFailureKind.userAction,
      message:
          'Android notifications are allowed, but Hike Reminders are '
          'disabled. Enable Hike Reminders in SummitTrack notification settings.',
      osStatus: 'allowed',
      firebaseMessagingStatus: 'authorized',
      channelStatus: 'disabled',
      channelBlocked: true,
      openSettingsSuggested: true,
    );
  }

  factory _NotificationPermissionResult.temporary(
    String message, {
    String channelStatus = 'unknown',
    String androidRequestStatus = 'not-requested',
  }) {
    return _NotificationPermissionResult(
      allowed: false,
      failureKind: NotificationFailureKind.temporary,
      message: message,
      osStatus: 'unknown',
      firebaseMessagingStatus: 'unknown',
      channelStatus: channelStatus,
      androidRequestStatus: androidRequestStatus,
    );
  }

  factory _NotificationPermissionResult.unsupported() {
    return const _NotificationPermissionResult(
      allowed: false,
      failureKind: NotificationFailureKind.unsupported,
      message: 'Notifications are not supported on this platform.',
      osStatus: 'unsupported',
      firebaseMessagingStatus: 'unsupported',
      channelStatus: 'unsupported',
    );
  }

  final bool allowed;
  final NotificationFailureKind failureKind;
  final String message;
  final String osStatus;
  final String firebaseMessagingStatus;
  final String channelStatus;
  final String androidRequestStatus;
  final bool appNotificationsExplicitlyDisabled;
  final bool channelBlocked;
  final bool openSettingsSuggested;
}

@immutable
class HikeNotificationPayload {
  const HikeNotificationPayload({
    required this.type,
    required this.uid,
    required this.hikeId,
    required this.hikeDateKey,
    required this.mountainId,
    required this.mountainName,
    required this.deviceId,
    required this.eventKey,
  });

  factory HikeNotificationPayload.fromMap(Map<String, dynamic> data) {
    return HikeNotificationPayload(
      type: _readString(data['type']),
      uid: _readString(data['uid']),
      hikeId: _readString(data['hikeId']),
      hikeDateKey: _readString(data['hikeDateKey']),
      mountainId: _readString(data['mountainId']),
      mountainName: _readString(data['mountainName']),
      deviceId: _readString(data['deviceId']),
      eventKey: _readString(data['eventKey']),
    );
  }

  final String type;
  final String uid;
  final String hikeId;
  final String hikeDateKey;
  final String mountainId;
  final String mountainName;
  final String deviceId;
  final String eventKey;

  bool get isValid {
    return type == HikeNotificationService.notificationType &&
        uid.isNotEmpty &&
        hikeId.isNotEmpty &&
        deviceId.isNotEmpty &&
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(hikeDateKey) &&
        eventKey ==
            buildHikeReminderEventKey(
              uid: uid,
              hikeId: hikeId,
              hikeDateKey: hikeDateKey,
              deviceId: deviceId,
            );
  }

  Map<String, String> toMap() {
    return {
      'type': type,
      'uid': uid,
      'hikeId': hikeId,
      'hikeDateKey': hikeDateKey,
      'mountainId': mountainId,
      'mountainName': mountainName,
      'deviceId': deviceId,
      'eventKey': eventKey,
    };
  }

  String toJsonString() => jsonEncode(toMap());

  static HikeNotificationPayload? tryParse(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map) {
        return null;
      }
      final payload = HikeNotificationPayload.fromMap(
        Map<String, dynamic>.from(decoded),
      );
      return payload.isValid ? payload : null;
    } catch (_) {
      return null;
    }
  }

  static HikeNotificationPayload? fromRemoteMessage(RemoteMessage message) {
    final payload = HikeNotificationPayload.fromMap(
      Map<String, dynamic>.from(message.data),
    );
    return payload.isValid ? payload : null;
  }

  static String _readString(Object? value) {
    return value?.toString().trim() ?? '';
  }
}

class _LocalEventState {
  const _LocalEventState({
    required this.eventKey,
    required this.uid,
    required this.hikeId,
    required this.hikeDateKey,
    required this.notificationId,
    required this.status,
  });

  final String eventKey;
  final String uid;
  final String hikeId;
  final String hikeDateKey;
  final int notificationId;
  final String status;

  _LocalEventState copyWith({String? status}) {
    return _LocalEventState(
      eventKey: eventKey,
      uid: uid,
      hikeId: hikeId,
      hikeDateKey: hikeDateKey,
      notificationId: notificationId,
      status: status ?? this.status,
    );
  }

  String toJsonString() {
    return jsonEncode({
      'eventKey': eventKey,
      'uid': uid,
      'hikeId': hikeId,
      'hikeDateKey': hikeDateKey,
      'notificationId': notificationId,
      'status': status,
    });
  }

  static _LocalEventState? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final data = Map<String, dynamic>.from(decoded);
      final eventKey = data['eventKey']?.toString() ?? '';
      final uid = data['uid']?.toString() ?? '';
      final hikeId = data['hikeId']?.toString() ?? '';
      final hikeDateKey = data['hikeDateKey']?.toString() ?? '';
      final notificationId = (data['notificationId'] as num?)?.toInt() ?? 0;
      final status = data['status']?.toString() ?? '';
      if (eventKey.isEmpty ||
          uid.isEmpty ||
          hikeId.isEmpty ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(hikeDateKey) ||
          notificationId <= 0 ||
          status.isEmpty) {
        return null;
      }
      return _LocalEventState(
        eventKey: eventKey,
        uid: uid,
        hikeId: hikeId,
        hikeDateKey: hikeDateKey,
        notificationId: notificationId,
        status: status,
      );
    } catch (_) {
      return null;
    }
  }
}
