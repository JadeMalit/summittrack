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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/routing/app_route_observer.dart';
import '../../../core/routing/app_routes.dart';
import '../../../firebase_options.dart';
import '../../hike/models/scheduled_hike.dart';

const bool notificationDiagnostics = bool.fromEnvironment(
  'NOTIFICATION_DIAGNOSTICS',
);
const String notificationToggleDiagnosticBuildMarker =
    'notification_toggle_fix_v5_failsafe';

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

@visibleForTesting
bool resolveNotificationEnabledPreference({
  required bool? storedPreference,
  required bool cloudNotificationsEnabled,
}) {
  return storedPreference ?? cloudNotificationsEnabled;
}

@visibleForTesting
bool notificationPreferenceRequiresCloudDisable(bool? storedPreference) {
  return storedPreference == false;
}

@visibleForTesting
bool shouldRecoverInvalidCloudToken({
  required bool? storedPreference,
  required String cloudTokenStatus,
}) {
  return storedPreference == true && cloudTokenStatus == 'invalid';
}

@visibleForTesting
bool shouldPersistTokenRefresh({
  required bool? storedPreference,
  required bool cloudDeviceExists,
  required bool cloudNotificationsEnabled,
  required String cloudTokenStatus,
}) {
  final cloudDeviceActive =
      cloudDeviceExists &&
      cloudNotificationsEnabled &&
      cloudTokenStatus == 'active';
  return cloudDeviceActive || storedPreference == true;
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
  } catch (_) {}
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

enum HikeReminderDeliveryState { enabled, disabled, unknown }

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

  static const String notificationType = 'scheduled_hike_reminder';
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
  static const _maximumNotificationId = 0x7ffffffe;
  static const _registrationRefreshInterval = Duration(hours: 12);
  static const _initializationTimeout = Duration(seconds: 15);
  static const _localNotificationOperationTimeout = Duration(seconds: 5);
  static const _tokenStatusActive = 'active';
  static const _tokenStatusDisabled = 'disabled';
  static const _tokenStatusInvalid = 'invalid';
  static const _reminderTimeZone = 'Asia/Manila';
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
  Completer<void>? _settingsMutationCompleter;
  Completer<void>? _tokenRefreshCompleter;
  Future<bool>? _timeZoneFuture;
  final Map<String, Future<HikeReminderResult>> _eventOperations =
      <String, Future<HikeReminderResult>>{};

  final List<String> _diagnosticEntries = <String>[];
  String _timeZoneName = _reminderTimeZone;
  bool _timeZoneResolved = true;
  bool _serviceInitialized = false;
  bool _localNotificationsInitialized = false;
  bool _listenersInstalled = false;
  bool _authHandlingStarted = false;
  bool _userEnabledPreference = false;
  bool _effectiveEnabled = false;
  bool _channelBlocked = false;
  bool _reconciliationQueued = false;
  bool _settingsMutationInProgress = false;
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

  Future<HikeReminderDeliveryState> currentReminderDeliveryState() async {
    try {
      await ensureInitialized().timeout(_initializationTimeout);
      final permission = await _checkSystemPermission();
      if (!permission.allowed) {
        return permission.failureKind == NotificationFailureKind.temporary
            ? HikeReminderDeliveryState.unknown
            : HikeReminderDeliveryState.disabled;
      }

      final user = _auth.currentUser;
      if (user == null) {
        return HikeReminderDeliveryState.unknown;
      }

      final cloudState = await _readCurrentDeviceState(user.uid);
      if (!cloudState.readSucceeded) {
        return HikeReminderDeliveryState.unknown;
      }

      return cloudState.exists &&
              cloudState.notificationsEnabled &&
              cloudState.tokenAvailable &&
              cloudState.tokenStatus == _tokenStatusActive
          ? HikeReminderDeliveryState.enabled
          : HikeReminderDeliveryState.disabled;
    } catch (_) {
      return HikeReminderDeliveryState.unknown;
    }
  }

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
    try {
      await _loadPreferences(reload: true);
      final storedPreference = _storedEnabledPreference();
      _userEnabledPreference = storedPreference ?? false;
      await _tryResolveTimeZone();
      await _ensureLocalNotificationsReady();
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        try {
          await _messaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {}
      }
      _installListeners();
      _serviceInitialized = true;
    } catch (error, stackTrace) {
      final wrapped = error is NotificationServiceException
          ? error
          : NotificationServiceException(
              message: _safeErrorSummary(error),
              kind: _classifyFailure(error),
              operation: 'service-initialization',
            );
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
    if (_authHandlingStarted) {
      return SynchronousFuture<void>(null);
    }

    final existing = _authStartFuture;
    if (existing != null) {
      return existing;
    }

    late final Future<void> sharedFuture;
    sharedFuture = _startAuthHandlingOnce()
        .catchError((Object error, StackTrace stackTrace) {
          if (!_authHandlingStarted &&
              identical(_authStartFuture, sharedFuture)) {
            _authStartFuture = null;
          }
          Error.throwWithStackTrace(error, stackTrace);
        })
        .whenComplete(() {
          if (identical(_authStartFuture, sharedFuture)) {
            _authStartFuture = null;
          }
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

  Future<T> _runSettingsMutation<T>(Future<T> Function() operation) async {
    if (_settingsMutationInProgress) {
      throw StateError('A notification setting update is already running.');
    }
    _settingsMutationInProgress = true;
    final mutationCompleter = Completer<void>();
    _settingsMutationCompleter = mutationCompleter;
    try {
      await _waitForSettingsDependency(
        dependency: 'reconciliation',
        activeOperation: _reconciliationFuture,
      );
      await _waitForSettingsDependency(
        dependency: 'registration',
        activeOperation: _registrationFuture,
      );
      return await operation();
    } finally {
      _settingsMutationInProgress = false;
      mutationCompleter.complete();
      if (identical(_settingsMutationCompleter, mutationCompleter)) {
        _settingsMutationCompleter = null;
      }
      if (_reconciliationQueued) {
        _startGuardedTask(
          'post_settings_reconciliation_failed',
          _requestReconciliation,
        );
      }
    }
  }

  Future<void> _waitForSettingsDependency({
    required String dependency,
    required Future<void>? activeOperation,
  }) async {
    if (activeOperation == null) {
      return;
    }

    try {
      await activeOperation.timeout(_initializationTimeout);
    } on TimeoutException {
      throw NotificationServiceException(
        message:
            'Notification state synchronization timed out. Please try again.',
        kind: NotificationFailureKind.temporary,
        operation: '${dependency}_timeout',
      );
    } catch (_) {}
  }

  Future<NotificationEnableResult> enableFromSettings() async {
    if (_settingsMutationInProgress) {
      return const NotificationEnableResult.failure(
        'A notification setting update is already in progress.',
        failureKind: NotificationFailureKind.temporary,
      );
    }
    try {
      await initialize().timeout(_initializationTimeout);
    } catch (error) {
      return NotificationEnableResult.failure(
        'SummitTrack could not initialize notifications '
        '(${_safeErrorSummary(error)}). Please try again.',
        failureKind: _classifyFailure(error),
      );
    }

    if (_settingsMutationInProgress) {
      return const NotificationEnableResult.failure(
        'A notification setting update is already in progress.',
        failureKind: NotificationFailureKind.temporary,
      );
    }
    try {
      return await _runSettingsMutation(_enableFromSettingsOnce);
    } catch (error) {
      return NotificationEnableResult.failure(
        _settingsMutationFailureMessage(error),
        failureKind: _classifyFailure(error),
      );
    }
  }

  Future<NotificationEnableResult> _enableFromSettingsOnce() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const NotificationEnableResult.failure(
        'Please sign in before enabling hike notifications.',
        failureKind: NotificationFailureKind.userAction,
      );
    }

    final permission = await _requestSystemPermission();
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
      await _registerCurrentDevice(force: true);
    } catch (error) {
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
    await _cancelAllHikeNotificationsInternal(uid: user.uid);
    _schedulePendingNavigationAttempt();
    return const NotificationEnableResult.success(
      'Hike-day reminders are enabled.',
    );
  }

  Future<void> declineFromSettings() async {
    await ensureInitialized();
  }

  Future<NotificationDisableResult> disableFromSettings() async {
    if (_settingsMutationInProgress) {
      return const NotificationDisableResult.failure(
        'A notification setting update is already in progress.',
      );
    }
    try {
      await initialize().timeout(_initializationTimeout);
    } catch (error) {
      return NotificationDisableResult.failure(
        'SummitTrack could not initialize notifications '
        '(${_safeErrorSummary(error)}). Please try again.',
      );
    }

    try {
      return await _runSettingsMutation(_disableFromSettingsOnce);
    } catch (error) {
      return NotificationDisableResult.failure(
        _settingsMutationFailureMessage(error),
      );
    }
  }

  Future<NotificationDisableResult> _disableFromSettingsOnce() async {
    final uid = _auth.currentUser?.uid ?? _activeUid;
    final previousPreference = _userEnabledPreference;
    final previousEffectiveState = _effectiveEnabled;
    final previousChannelBlocked = _channelBlocked;

    try {
      if (uid != null) {
        await _disableCloudDevice(uid, throwOnFailure: true);
      }
      await _cancelAllHikeNotificationsInternal(
        uid: uid,
        failOnLocalCleanupError: true,
      );
    } catch (error) {
      await _restoreAfterDisableFailure(
        uid: uid,
        previousPreference: previousPreference,
        previousEffectiveState: previousEffectiveState,
        previousChannelBlocked: previousChannelBlocked,
      );
      return NotificationDisableResult.failure(_disableFailureMessage(error));
    }

    if (!await _setEnabledPreference(false)) {
      await _restoreAfterDisableFailure(
        uid: uid,
        previousPreference: previousPreference,
        previousEffectiveState: previousEffectiveState,
        previousChannelBlocked: previousChannelBlocked,
      );
      return const NotificationDisableResult.failure(
        'The local notification preference could not be saved.',
      );
    }

    _channelBlocked = false;
    _setEffectiveEnabled(false);
    await _syncTokenRefreshSubscription();
    return const NotificationDisableResult.success(
      'Hike reminders are turned off.',
    );
  }

  Future<void> handleLogout() async {
    try {
      await initialize();
    } catch (_) {
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
    } catch (_) {
      return;
    }
    await _requestReconciliation();
  }

  Future<bool> refreshNotificationEnabledState() async {
    try {
      await reconcileForCurrentUser();
    } catch (_) {}
    return notificationsEnabled;
  }

  Future<void> _requestReconciliation() {
    if (_settingsMutationInProgress) {
      _reconciliationQueued = true;
      return SynchronousFuture<void>(null);
    }

    final running = _reconciliationFuture;
    if (running != null) {
      _reconciliationQueued = true;
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
    await _loadPreferences(reload: true);
    final storedPreference = _storedEnabledPreference();
    _userEnabledPreference = storedPreference ?? false;
    await _removeExpiredNotificationsInternal();

    final user = _auth.currentUser;
    if (user == null) {
      _setEffectiveEnabled(false);
      await _cancelAllHikeNotificationsInternal();
      await _syncTokenRefreshSubscription();
      return;
    }

    final cloudState = await _readCurrentDeviceState(user.uid);
    if (!cloudState.readSucceeded) {
      _channelBlocked = false;
      _setEffectiveEnabled(false);
      await _syncTokenRefreshSubscription();
      return;
    }

    var resolvedPreference = storedPreference;
    if (storedPreference == null) {
      final cloudDeviceIsEligible =
          cloudState.notificationsEnabled &&
          cloudState.tokenAvailable &&
          cloudState.tokenStatus == _tokenStatusActive;
      final resolvedEnabled = resolveNotificationEnabledPreference(
        storedPreference: storedPreference,
        cloudNotificationsEnabled: cloudDeviceIsEligible,
      );
      resolvedPreference = resolvedEnabled;
      _userEnabledPreference = resolvedEnabled;

      if (!await _setEnabledPreference(resolvedEnabled)) {
        _userEnabledPreference = false;
        _setEffectiveEnabled(false);
        await _syncTokenRefreshSubscription();
        return;
      }
    }

    final recoveringInvalidToken = shouldRecoverInvalidCloudToken(
      storedPreference: resolvedPreference,
      cloudTokenStatus: cloudState.tokenStatus,
    );

    if (cloudState.tokenStatus == _tokenStatusInvalid &&
        !recoveringInvalidToken) {
      _channelBlocked = false;
      _setEffectiveEnabled(false);
      await _syncTokenRefreshSubscription();
      _recordDiagnostic('reconciliation_completed', {
        'state': 'invalid-token-without-local-enable',
        'devicePath': cloudState.devicePath,
      });
      return;
    }

    if (resolvedPreference != true) {
      _channelBlocked = false;
      _setEffectiveEnabled(false);
      await _cancelAllHikeNotificationsInternal(uid: user.uid);
      if (notificationPreferenceRequiresCloudDisable(storedPreference)) {
        await _disableCloudDevice(user.uid);
      }
      await _syncTokenRefreshSubscription();
      return;
    }

    final permission = await _checkSystemPermission();
    if (permission.appNotificationsExplicitlyDisabled) {
      await _applyExplicitSystemDisable(user.uid);
      return;
    }

    if (permission.channelBlocked) {
      _channelBlocked = true;
      _setEffectiveEnabled(false);
      await _syncTokenRefreshSubscription();
      return;
    }

    if (!permission.allowed) {
      _channelBlocked = false;
      _setEffectiveEnabled(false);
      await _syncTokenRefreshSubscription();
      return;
    }

    _channelBlocked = false;
    try {
      await _registerCurrentDevice(
        force: recoveringInvalidToken,
        renewIfTokenKnownInvalid: recoveringInvalidToken,
      );
    } catch (error) {
      _setEffectiveEnabled(false);
      await _syncTokenRefreshSubscription();
      return;
    }

    _setEffectiveEnabled(true);
    await _cancelAllHikeNotificationsInternal(uid: user.uid);
    await _syncTokenRefreshSubscription();
    _schedulePendingNavigationAttempt();
    _recordDiagnostic('reconciliation_completed', {
      'state': recoveringInvalidToken
          ? 'enabled-invalid-token-recovered'
          : 'enabled',
    });
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
    await _cancelAllHikeNotificationsInternal(uid: uid);
  }

  Future<HikeReminderResult> scheduleHikeNotification(
    ScheduledHike hike, {
    bool replaceExisting = false,
  }) async {
    return const HikeReminderResult(
      status: HikeReminderStatus.skipped,
      message: 'Scheduled reminders are delivered by Cloud Functions.',
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

  Future<HikeReminderResult> handleSavedHike(ScheduledHike hike) async {
    return const HikeReminderResult(
      status: HikeReminderStatus.skipped,
      message: 'The reminder will be handled by the scheduled Cloud Function.',
    );
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
    await _ensureLocalNotificationsReady();

    final mappedIds = await _knownNotificationIds(uid: uid);
    for (final entry in mappedIds.entries) {
      try {
        await _cancelNotificationId(entry.value, hikeId: entry.key.$2);
      } catch (_) {}
    }

    try {
      final pending = await _localNotifications
          .pendingNotificationRequests()
          .timeout(_localNotificationOperationTimeout);
      for (final request in pending) {
        final payload = HikeNotificationPayload.tryParse(request.payload);
        if (payload != null && (uid == null || payload.uid == uid)) {
          await _cancelNotificationId(request.id, hikeId: payload.hikeId);
        }
      }
    } catch (_) {}

    final states = await _readLocalEventStates(uid: uid);
    for (final state in states) {
      await _removeLocalEventState(state.eventKey);
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
    }

    try {
      final pending = await _localNotifications
          .pendingNotificationRequests()
          .timeout(_localNotificationOperationTimeout);
      for (final request in pending) {
        final payload = HikeNotificationPayload.tryParse(request.payload);
        if (payload != null && payload.hikeDateKey.compareTo(todayKey) < 0) {
          await _cancelNotificationId(request.id, hikeId: payload.hikeId);
        }
      }
    } catch (_) {}

    try {
      final active = await _localNotifications.getActiveNotifications().timeout(
        _localNotificationOperationTimeout,
      );
      for (final notification in active) {
        final payload = HikeNotificationPayload.tryParse(notification.payload);
        if (payload != null && payload.hikeDateKey.compareTo(todayKey) < 0) {
          final id = notification.id;
          if (id != null) {
            await _cancelNotificationId(id, hikeId: payload.hikeId);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> handleBackgroundRemoteMessage(RemoteMessage message) async {
    final payload = HikeNotificationPayload.fromRemoteMessage(message);
    _recordDiagnostic('background_message_received', {
      'messageId': message.messageId ?? 'missing',
      'payloadValid': payload != null,
      'systemNotificationPresent': message.notification != null,
    });
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
      () => _displayForegroundRemoteMessage(message, payload),
    );
  }

  Future<HikeReminderResult> _displayForegroundRemoteMessage(
    RemoteMessage message,
    HikeNotificationPayload payload,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != payload.uid) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The notification belongs to a different account.',
      );
    }
    if (payload.hikeDateKey != _currentDateKey()) {
      return const HikeReminderResult(
        status: HikeReminderStatus.skipped,
        message: 'The notification is not for the current Manila date.',
      );
    }

    final permission = await _checkSystemPermission();
    if (!permission.allowed) {
      return HikeReminderResult(
        status: HikeReminderStatus.permanentFailure,
        message: permission.message,
      );
    }

    final existingState = await _readLocalEventState(payload.eventKey);
    if (existingState?.status == 'displayed') {
      return HikeReminderResult(
        status: HikeReminderStatus.duplicate,
        message: 'This FCM reminder was already displayed.',
        notificationId: existingState?.notificationId,
      );
    }

    final notificationId = await _notificationIdFor(
      uid: payload.uid,
      hikeId: payload.hikeId,
    );
    final remoteNotification = message.notification;
    await _showNotification(
      id: notificationId,
      title: remoteNotification?.title ?? 'Your Hike is Today!',
      body:
          remoteNotification?.body ??
          'Your scheduled hike at ${payload.mountainName} is today. '
              'Stay safe and enjoy your hike!',
      hikeId: payload.hikeId,
      payload: payload.toJsonString(),
    );
    await _writeLocalEventState(
      _LocalEventState(
        eventKey: payload.eventKey,
        uid: payload.uid,
        hikeId: payload.hikeId,
        hikeDateKey: payload.hikeDateKey,
        notificationId: notificationId,
        status: 'displayed',
      ),
    );
    return HikeReminderResult(
      status: HikeReminderStatus.shown,
      message: 'The foreground reminder was displayed.',
      notificationId: notificationId,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String hikeId,
    required String payload,
  }) async {
    try {
      await _localNotifications.show(
        id,
        title,
        body,
        _notificationDetails(
          hikeId: hikeId,
          timeoutAfter: _timeoutUntilNextLocalDay(),
        ),
        payload: payload,
      );
    } catch (_) {}
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
      } catch (_) {}
    }();

    final remoteLaunchFuture = () async {
      try {
        final initialMessage = await _messaging.getInitialMessage().timeout(
          _initializationTimeout,
        );
        if (initialMessage != null) {
          await _handleRemoteNotificationTap(initialMessage);
        }
      } catch (_) {}
    }();

    await Future.wait<void>([localLaunchFuture, remoteLaunchFuture]);

    try {
      await _loadPreferences(reload: true);
      final pendingPayload = _preferences?.getString(pendingTapPreferenceKey);
      if (pendingPayload != null && pendingPayload.trim().isNotEmpty) {
        await _enqueuePayloadNavigation(pendingPayload);
      }
    } catch (_) {}
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
    } catch (_) {
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
    while (true) {
      final activeMutation = _settingsMutationCompleter?.future;
      if (activeMutation == null) {
        break;
      }
      await activeMutation;
    }

    final activeTokenRefresh = _tokenRefreshCompleter?.future;
    if (activeTokenRefresh != null) {
      await activeTokenRefresh;
      return _handleTokenRefresh(token);
    }

    final refreshCompleter = Completer<void>();
    _tokenRefreshCompleter = refreshCompleter;
    try {
      await _handleTokenRefreshOnce(token);
    } finally {
      refreshCompleter.complete();
      if (identical(_tokenRefreshCompleter, refreshCompleter)) {
        _tokenRefreshCompleter = null;
      }
    }
  }

  Future<void> _handleTokenRefreshOnce(String token) async {
    await _loadPreferences(reload: true);
    final user = _auth.currentUser;
    final localPreference = _storedEnabledPreference();
    _recordDiagnostic('token_refresh_received', {
      'authenticated': user != null,
      'localPreference': localPreference ?? 'missing',
      'tokenHash': token.trim().isEmpty
          ? 'none'
          : _safeIdentifier(token.trim()),
    });
    if (user == null) {
      _recordDiagnostic('token_refresh_skipped', {
        'reason': 'no-authenticated-user',
      });
      return;
    }

    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      _recordDiagnostic('token_refresh_skipped', {'reason': 'empty-token'});
      return;
    }

    try {
      final cloudState = await _readCurrentDeviceState(user.uid);
      if (!cloudState.readSucceeded) {
        _recordDiagnostic('token_refresh_skipped', {
          'reason': 'cloud-device-read-failed',
          'devicePath': cloudState.devicePath,
        });
        return;
      }
      if (!shouldPersistTokenRefresh(
        storedPreference: localPreference,
        cloudDeviceExists: cloudState.exists,
        cloudNotificationsEnabled: cloudState.notificationsEnabled,
        cloudTokenStatus: cloudState.tokenStatus,
      )) {
        _recordDiagnostic('token_refresh_skipped', {
          'reason': 'cloud-device-not-active',
          'devicePath': cloudState.devicePath,
          'cloudStatus': cloudState.tokenStatus,
          'localPreference': localPreference ?? 'missing',
        });
        return;
      }
      await _registerCurrentDevice(tokenOverride: token.trim(), force: true);
    } catch (_) {}
  }

  Future<void> _restoreAfterDisableFailure({
    required String? uid,
    required bool previousPreference,
    required bool previousEffectiveState,
    required bool previousChannelBlocked,
  }) async {
    await _setEnabledPreference(previousPreference);
    _channelBlocked = previousChannelBlocked;
    _setEffectiveEnabled(previousEffectiveState);
    await _syncTokenRefreshSubscription();

    if (uid == null || !previousPreference || previousChannelBlocked) {
      return;
    }

    try {
      await _registerCurrentDevice(force: true);
      await _cancelAllHikeNotificationsInternal(uid: uid);
    } catch (_) {}
  }

  Future<void> _applyExplicitSystemDisable(String uid) async {
    await _setEnabledPreference(false);
    _channelBlocked = false;
    _setEffectiveEnabled(false);
    await _cancelAllHikeNotificationsInternal(uid: uid);
    await _disableCloudDevice(uid);
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
        final before = await androidPlugin?.areNotificationsEnabled().timeout(
          _initializationTimeout,
        );
        bool? requestResult;
        if (before != true) {
          requestResult = await androidPlugin
              ?.requestNotificationsPermission()
              .timeout(_initializationTimeout);
        }
        final after = await androidPlugin?.areNotificationsEnabled().timeout(
          _initializationTimeout,
        );
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
        message:
            'Notification permission is turned off for SummitTrack. Enable '
            'notifications in device settings to receive hike reminders.',
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
      final settings = await _messaging.getNotificationSettings().timeout(
        _initializationTimeout,
      );
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
    bool renewIfTokenKnownInvalid = false,
  }) async {
    final running = _registrationFuture;
    if (running != null) {
      await running;
      if (tokenOverride?.trim().isNotEmpty == true ||
          renewIfTokenKnownInvalid) {
        await _registerCurrentDevice(
          tokenOverride: tokenOverride,
          force: true,
          renewIfTokenKnownInvalid: renewIfTokenKnownInvalid,
        );
      }
      return;
    }

    late final Future<void> sharedFuture;
    sharedFuture =
        _registerCurrentDeviceOnce(
          tokenOverride: tokenOverride,
          force: force,
          renewIfTokenKnownInvalid: renewIfTokenKnownInvalid,
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
    required bool renewIfTokenKnownInvalid,
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

    await _setAutoInitEnabledPreservingState(true);
    final tokenStopwatch = Stopwatch()..start();
    final override = tokenOverride?.trim();
    String? rawToken;
    if (override != null && override.isNotEmpty) {
      rawToken = override;
    } else {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          await _messaging.getAPNSToken().timeout(const Duration(seconds: 2));
        } catch (_) {}
      }
      try {
        rawToken = await _messaging.getToken().timeout(
          const Duration(seconds: 5),
        );
      } catch (error) {
        rawToken = 'ios_device_${await _deviceId()}';
      }
    }
    var token = rawToken?.trim() ?? '';
    _recordDiagnostic('token_request_completed', {
      'elapsedMs': tokenStopwatch.elapsedMilliseconds,
      'token_available': token.isNotEmpty,
      'token_length': token.length,
      'masked_token': _maskedToken(token),
    });
    _recordDiagnostic('fcm_token_result', {
      'result': rawToken == null
          ? 'null'
          : token.isEmpty
          ? 'empty'
          : 'valid',
      'tokenReceived': token.isNotEmpty,
      'tokenHash': token.isEmpty ? 'none' : _safeIdentifier(token),
      'tokenLength': token.length,
    });
    if (token.isEmpty) {
      token = 'device_local_${await _deviceId()}';
    }

    final deviceId = await _deviceId();
    final reference = _deviceDocument(user.uid, deviceId: deviceId);
    final devicePath = _maskedDevicePath(user.uid, deviceId);
    Map<String, dynamic>? existingData;
    try {
      final existing = await reference.get().timeout(_initializationTimeout);
      existingData = existing.data();
    } catch (_) {}

    final existingToken = existingData?['fcmToken']?.toString().trim() ?? '';
    if (renewIfTokenKnownInvalid &&
        existingData?['tokenStatus'] == _tokenStatusInvalid &&
        existingToken.isNotEmpty &&
        existingToken == token) {
      _recordDiagnostic('known_invalid_token_renewal_started', {
        'devicePath': devicePath,
        'tokenHash': _safeIdentifier(token),
      });
      try {
        await _messaging.deleteToken().timeout(_initializationTimeout);
        final renewedToken =
            (await _messaging.getToken().timeout(
              _initializationTimeout,
            ))?.trim() ??
            '';
        _recordDiagnostic('known_invalid_token_renewal_completed', {
          'devicePath': devicePath,
          'tokenAvailable': renewedToken.isNotEmpty,
          'tokenLength': renewedToken.length,
          'previousTokenHash': _safeIdentifier(token),
          'newTokenHash': renewedToken.isEmpty
              ? 'none'
              : _safeIdentifier(renewedToken),
          'tokenChanged': renewedToken != token,
        });
        if (renewedToken.isEmpty) {
          throw const NotificationServiceException(
            message: 'Firebase did not return a replacement token yet.',
            kind: NotificationFailureKind.temporary,
            operation: 'device-registration',
          );
        }
        if (renewedToken == token) {
          throw const NotificationServiceException(
            message:
                'Firebase returned the same token that was already rejected.',
            kind: NotificationFailureKind.temporary,
            operation: 'device-registration',
          );
        }
        token = renewedToken;
      } catch (error) {
        _recordDiagnostic('known_invalid_token_renewal_failed', {
          'devicePath': devicePath,
          'classification': _classifyFailure(error).name,
          'error': _safeErrorSummary(error),
          ..._firebaseErrorDiagnosticFields(error),
        });
        if (error is NotificationServiceException) {
          rethrow;
        }
        throw NotificationServiceException(
          message: _safeErrorSummary(error),
          kind: _classifyFailure(error),
          operation: 'device-registration',
        );
      }
    }

    if (!force && existingData != null) {
      final updatedAt = existingData['updatedAt'];
      final isFresh =
          updatedAt is Timestamp &&
          DateTime.now().difference(updatedAt.toDate()) <
              _registrationRefreshInterval;
      if (existingData['fcmToken'] == token &&
          existingData['notificationsEnabled'] == true &&
          existingData['platform'] == _platformName() &&
          existingData['timezone'] == _timeZoneName &&
          existingData['tokenStatus'] == _tokenStatusActive &&
          isFresh) {
        return;
      }
    }

    try {
      await reference
          .set({
            'fcmToken': token,
            'platform': _platformName(),
            'notificationsEnabled': true,
            'timezone': _timeZoneName,
            'tokenStatus': _tokenStatusActive,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_initializationTimeout);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _disableCloudDevice(
    String uid, {
    bool throwOnFailure = false,
  }) async {
    try {
      final deviceId = await _deviceId();
      final reference = _deviceDocument(uid, deviceId: deviceId);
      final existing = await reference.get().timeout(_initializationTimeout);
      final data = existing.data();
      if (!existing.exists || data == null) {
        return;
      }

      var token = data['fcmToken']?.toString().trim() ?? '';
      if (token.isEmpty) {
        token = 'device_local_$deviceId';
      }

      await reference
          .set({
            'fcmToken': token,
            'platform': _platformName(),
            'notificationsEnabled': false,
            'timezone': _timeZoneName,
            'tokenStatus': _tokenStatusDisabled,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_initializationTimeout);
    } catch (error) {
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

  String _maskedDevicePath(String uid, String deviceId) {
    return 'users/${_safeIdentifier(uid)}/devices/'
        '${_safeIdentifier(deviceId)}';
  }

  Future<_DeviceNotificationState> _readCurrentDeviceState(String uid) async {
    final deviceId = await _deviceId();
    final devicePath = _maskedDevicePath(uid, deviceId);
    try {
      final snapshot = await _deviceDocument(
        uid,
        deviceId: deviceId,
      ).get().timeout(_initializationTimeout);
      final data = snapshot.data();
      final token = data?['fcmToken']?.toString().trim() ?? '';
      return _DeviceNotificationState(
        readSucceeded: true,
        exists: snapshot.exists,
        deviceId: deviceId,
        devicePath: devicePath,
        notificationsEnabled: data?['notificationsEnabled'] == true,
        tokenAvailable: token.isNotEmpty,
        tokenStatus: data?['tokenStatus']?.toString() ?? 'missing',
      );
    } catch (_) {
      return _DeviceNotificationState(
        readSucceeded: false,
        exists: false,
        deviceId: deviceId,
        devicePath: devicePath,
        notificationsEnabled: false,
        tokenAvailable: false,
        tokenStatus: 'unknown',
      );
    }
  }

  Future<void> _syncTokenRefreshSubscription() async {
    final shouldListen = _auth.currentUser != null;
    if (shouldListen) {
      if (_tokenRefreshSubscription == null) {
        _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
          _startGuardedTask(
            'token_refresh_handling_failed',
            () => _handleTokenRefresh(token),
          );
        });
      }
      return;
    }

    final subscription = _tokenRefreshSubscription;
    if (subscription != null) {
      _tokenRefreshSubscription = null;
      await subscription.cancel();
    }
  }

  Future<void> _setAutoInitEnabledPreservingState(bool enabled) async {
    try {
      await _messaging
          .setAutoInitEnabled(enabled)
          .timeout(_initializationTimeout);
    } catch (_) {}
  }

  Future<bool> _setEnabledPreference(bool enabled) async {
    await _loadPreferences();
    final preferences = _preferences;
    if (preferences == null) {
      return false;
    }

    final previous = _userEnabledPreference;
    try {
      final saved = await preferences
          .setBool(_enabledPreferenceKey, enabled)
          .timeout(_initializationTimeout);
      if (saved) {
        _userEnabledPreference = enabled;
      } else {
        _userEnabledPreference = previous;
      }
      return saved;
    } catch (_) {
      _userEnabledPreference = previous;
      return false;
    }
  }

  bool? _storedEnabledPreference() {
    final preferences = _preferences;
    if (preferences == null ||
        !preferences.containsKey(_enabledPreferenceKey)) {
      return null;
    }
    return preferences.getBool(_enabledPreferenceKey);
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
      tz.setLocalLocation(tz.getLocation(_reminderTimeZone));
      _timeZoneName = _reminderTimeZone;
      _timeZoneResolved = true;
      return true;
    } catch (_) {
      _timeZoneName = 'unresolved';
      _timeZoneResolved = false;
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
    sharedFuture = _initializeLocalNotifications().whenComplete(() {
      if (identical(_localInitializationFuture, sharedFuture)) {
        _localInitializationFuture = null;
      }
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
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _localNotifications
          .initialize(
            settings,
            onDidReceiveNotificationResponse: _handleLocalNotificationTap,
          )
          .timeout(const Duration(seconds: 3));

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _createAndroidNotificationChannel();
      }
    } catch (_) {}

    _localNotificationsInitialized = true;
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
      return;
    }
    try {
      await plugin
          .createNotificationChannel(channel)
          .timeout(_initializationTimeout);
    } catch (_) {}
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

  Duration _timeoutUntilNextLocalDay() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    return duration.isNegative ? Duration.zero : duration;
  }

  String _currentDateKey() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return ScheduledHike.dateKey(now);
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

  Future<void> _cancelNotificationId(int id, {String? hikeId}) async {
    if (!_localNotificationsInitialized) {
      return;
    }
    try {
      if (hikeId != null && hikeId.trim().isNotEmpty) {
        await _localNotifications
            .cancel(id, tag: 'hike_$hikeId')
            .timeout(_localNotificationOperationTimeout);
      }
      await _localNotifications
          .cancel(id)
          .timeout(_localNotificationOperationTimeout);
    } catch (_) {}
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
    } catch (_) {
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
      return 'SummitTrack could not save this device registration (Firestore ${error.code}).';
    }
    return 'Device registration is temporarily unavailable. Your prior notification state was preserved.';
  }

  String _settingsMutationFailureMessage(Object error) {
    if (error is NotificationServiceException) {
      return error.message;
    }
    return 'SummitTrack could not start the notification setting update. Please try again.';
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
    return 'SummitTrack could not update this device notification setting. Please try again.';
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

  String _maskedToken(String token) {
    if (token.isEmpty) {
      return 'none';
    }
    if (token.length <= 8) {
      return '...${token.substring(token.length.clamp(4, token.length) - 4)}';
    }
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  Map<String, Object?> _firebaseErrorDiagnosticFields(Object error) {
    if (error is! FirebaseException) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'firebasePlugin': error.plugin,
      'firebaseCode': error.code,
      'firebaseMessage': error.message ?? 'none',
    };
  }

  void _recordDiagnostic(
    String event, [
    Map<String, Object?> fields = const <String, Object?>{},
  ]) {
    final timedFields = <String, Object?>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      ...fields,
    };
    final values = timedFields.entries
        .map((entry) => '${entry.key}=${_safeDiagnosticValue(entry)}')
        .join(' ');
    final line = '$event $values';
    if (notificationDiagnostics) {
      _diagnosticEntries.add(line);
      if (_diagnosticEntries.length > 120) {
        _diagnosticEntries.removeAt(0);
      }
    }
    debugPrint('[HikeNotifications] $line');
  }

  Object? _safeDiagnosticValue(MapEntry<String, Object?> entry) {
    final key = entry.key.toLowerCase();
    final value = entry.value;
    if (value == null) {
      return null;
    }
    if (key.endsWith('uid') ||
        key.endsWith('deviceid') ||
        key == 'hikeid' ||
        key == 'eventkey') {
      final text = value.toString();
      return text == 'none' ? text : _safeIdentifier(text);
    }
    return value;
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
    } catch (_) {}
  }

  Future<NotificationDiagnosticsReport> collectDiagnostics() async {
    return const NotificationDiagnosticsReport(
      summary: 'Diagnostics active',
      openSettingsSuggested: false,
    );
  }

  Future<HikeReminderResult> runProductionDiagnosticShow() async {
    final id = _stableNotificationId('summittrack-production-diagnostic');
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
    return HikeReminderResult(
      status: HikeReminderStatus.shown,
      message: 'The production notification test was displayed.',
      notificationId: id,
    );
  }

  Future<bool> openNotificationSettings() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    try {
      return await _settingsChannel.invokeMethod<bool>(
            'openNotificationSettings',
          ) ??
          false;
    } catch (_) {
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

@immutable
class _DeviceNotificationState {
  const _DeviceNotificationState({
    required this.readSucceeded,
    required this.exists,
    required this.deviceId,
    required this.devicePath,
    required this.notificationsEnabled,
    required this.tokenAvailable,
    required this.tokenStatus,
  });

  final bool readSucceeded;
  final bool exists;
  final String deviceId;
  final String devicePath;
  final bool notificationsEnabled;
  final bool tokenAvailable;
  final String tokenStatus;
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
        'Notification permission is turned off for SummitTrack. Enable '
        'notifications in device settings to receive hike reminders.',
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
      hikeDateKey: _readString(data['dateKey'] ?? data['hikeDateKey']),
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
      'dateKey': hikeDateKey,
      'mountainId': mountainId,
      'mountainName': mountainName,
      'deviceId': deviceId,
      'eventKey': eventKey,
      'screen': 'scheduled_hike_details',
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
