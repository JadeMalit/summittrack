import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/auth/screens/SignIN_SignUP/pre_hike_loading_screen.dart';
import '../../shared/widgets/connection_transition_modal.dart';
import '../routing/app_route_observer.dart';
import '../routing/app_routes.dart';
import '../services/connectivity_service.dart';
import '../state/app_mode_provider.dart';

enum _ConnectionCheckTrigger { startup, connectivityChange, poll, resume }

enum _ConnectionTransitionKind { internetRestored, internetLost }

class InternetStatusController extends StatefulWidget {
  const InternetStatusController({super.key, required this.child});

  final Widget child;

  @override
  State<InternetStatusController> createState() =>
      _InternetStatusControllerState();
}

class _InternetStatusControllerState extends State<InternetStatusController>
    with WidgetsBindingObserver {
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AppModeProvider _appModeProvider = AppModeProvider.instance;

  static const _connectivityChangeDebounce = Duration(milliseconds: 800);
  static const _transitionStabilityDelay = Duration(milliseconds: 900);
  static const _pollInterval = Duration(seconds: 10);
  static const _reconnectPollInterval = Duration(seconds: 2);

  StreamSubscription<void>? _connectivitySubscription;
  Timer? _connectivityChangeDebounceTimer;
  Timer? _pollTimer;

  InternetConnectionStatus _lastKnownConnectionState =
      InternetConnectionStatus.unknown;
  _ConnectionCheckTrigger? _pendingConnectionCheckTrigger;
  bool _isInitialConnectionCheckComplete = false;
  bool _isCheckingConnection = false;
  bool _isTransitionModalShowing = false;
  bool _isReconnectLoadingShowing = false;
  bool _userChoseStayOffline = false;
  bool _userChoseStayOnline = false;
  String? _previousAuthenticatedUserId;
  int _connectionCheckSerial = 0;
  _ConnectionTransitionKind? _activeTransitionModal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _startMonitoringConnection();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _connectivityChangeDebounceTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleConnectionCheck(_ConnectionCheckTrigger.resume);
    }
  }

  void _startMonitoringConnection() {
    if (_connectivitySubscription != null) {
      return;
    }

    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((_) {
          _scheduleConnectionCheck(_ConnectionCheckTrigger.connectivityChange);
        });

    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _scheduleConnectionCheck(_ConnectionCheckTrigger.poll);
    });

    _scheduleConnectionCheck(_ConnectionCheckTrigger.startup);
  }

  void _scheduleConnectionCheck(_ConnectionCheckTrigger trigger) {
    if (!mounted) {
      return;
    }

    if (trigger == _ConnectionCheckTrigger.connectivityChange) {
      _connectivityChangeDebounceTimer?.cancel();
      _connectivityChangeDebounceTimer = Timer(_connectivityChangeDebounce, () {
        unawaited(_checkConnection(trigger));
      });
      return;
    }

    unawaited(_checkConnection(trigger));
  }

  Future<void> _checkConnection(_ConnectionCheckTrigger trigger) async {
    if (!mounted) {
      return;
    }

    final checkSerial = ++_connectionCheckSerial;

    if (_isCheckingConnection) {
      _pendingConnectionCheckTrigger = trigger;
      return;
    }

    _isCheckingConnection = true;

    try {
      var status = await _connectivityService.checkInternetStatus(
        attempts: trigger == _ConnectionCheckTrigger.startup ? 2 : 3,
        isStartupCheck: trigger == _ConnectionCheckTrigger.startup,
      );

      if (!mounted || checkSerial != _connectionCheckSerial) {
        return;
      }

      if (_shouldConfirmStableTransition(status)) {
        await Future<void>.delayed(_transitionStabilityDelay);

        if (!mounted || checkSerial != _connectionCheckSerial) {
          return;
        }

        status = await _connectivityService.checkInternetStatus(attempts: 2);

        if (!mounted || checkSerial != _connectionCheckSerial) {
          return;
        }
      }

      _applyConnectionStatus(status);
    } finally {
      if (mounted) {
        _isCheckingConnection = false;

        if (checkSerial != _connectionCheckSerial) {
          final pendingTrigger =
              _pendingConnectionCheckTrigger ?? _ConnectionCheckTrigger.poll;
          _pendingConnectionCheckTrigger = null;
          unawaited(_checkConnection(pendingTrigger));
        }
      }
    }
  }

  bool _shouldConfirmStableTransition(InternetConnectionStatus status) {
    if (!_isInitialConnectionCheckComplete ||
        _lastKnownConnectionState == InternetConnectionStatus.unknown) {
      return false;
    }

    return (status == InternetConnectionStatus.online ||
            status == InternetConnectionStatus.offline) &&
        status != _lastKnownConnectionState;
  }

  void _applyConnectionStatus(InternetConnectionStatus status) {
    if (status == InternetConnectionStatus.unknown ||
        status == InternetConnectionStatus.checking) {
      return;
    }

    _dismissStaleTransitionModal(status);

    if (!_isInitialConnectionCheckComplete) {
      _lastKnownConnectionState = status;
      _isInitialConnectionCheckComplete = true;
      return;
    }

    final previousStatus = _lastKnownConnectionState;

    if (previousStatus == status) {
      _handleStableStatus(status);
      return;
    }

    if (_shouldDelayTransitionUntilCurrentDialogCloses(
      previousStatus,
      status,
    )) {
      return;
    }

    _lastKnownConnectionState = status;

    if (status == InternetConnectionStatus.online) {
      _userChoseStayOnline = false;
      _dismissReconnectLoadingIfShowing();

      if (previousStatus == InternetConnectionStatus.offline) {
        _handleInternetRestored();
      }
      return;
    }

    _userChoseStayOffline = false;

    if (previousStatus == InternetConnectionStatus.online) {
      _handleInternetLost();
    }
  }

  void _handleStableStatus(InternetConnectionStatus status) {
    if (status == InternetConnectionStatus.online) {
      _userChoseStayOnline = false;
      _dismissReconnectLoadingIfShowing();
    }
  }

  bool _shouldDelayTransitionUntilCurrentDialogCloses(
    InternetConnectionStatus previousStatus,
    InternetConnectionStatus nextStatus,
  ) {
    if (_isTransitionModalShowing || _isReconnectLoadingShowing) {
      return false;
    }

    if (!appRouteObserver.isPopupRouteOnTop) {
      return false;
    }

    final needsRestoredModal =
        previousStatus == InternetConnectionStatus.offline &&
        nextStatus == InternetConnectionStatus.online &&
        _canShowInternetRestoredModal(ignorePopup: true);
    final needsLostModal =
        previousStatus == InternetConnectionStatus.online &&
        nextStatus == InternetConnectionStatus.offline &&
        _canShowInternetLostModal(ignorePopup: true);

    return needsRestoredModal || needsLostModal;
  }

  void _handleInternetRestored() {
    if (!_canShowInternetRestoredModal()) {
      return;
    }

    unawaited(_showInternetRestoredModal());
  }

  void _handleInternetLost() {
    if (!_canShowInternetLostModal()) {
      return;
    }

    unawaited(_showInternetLostModal());
  }

  bool _canShowInternetRestoredModal({bool ignorePopup = false}) {
    return mounted &&
        _appModeProvider.isOfflineMode &&
        !_userChoseStayOffline &&
        !_isTransitionModalShowing &&
        !PreHikeLoginTransition.isActive &&
        (ignorePopup || !appRouteObserver.isPopupRouteOnTop) &&
        appNavigatorKey.currentContext != null;
  }

  bool _canShowInternetLostModal({bool ignorePopup = false}) {
    return mounted &&
        _appModeProvider.isOnlineMode &&
        FirebaseAuth.instance.currentUser != null &&
        !_userChoseStayOnline &&
        !_isTransitionModalShowing &&
        !PreHikeLoginTransition.isActive &&
        !_isAuthRouteActive &&
        (ignorePopup || !appRouteObserver.isPopupRouteOnTop) &&
        appNavigatorKey.currentContext != null;
  }

  bool get _isAuthRouteActive {
    final routeName = appRouteObserver.currentRouteName;
    if (routeName == null) {
      return false;
    }

    final path = Uri.parse(AppRoutes.normalizeLocation(routeName)).path;
    return path == AppRoutes.login ||
        path == AppRoutes.signup ||
        path == '/forgot-password';
  }

  Future<void> _showInternetRestoredModal() async {
    final context = appNavigatorKey.currentContext;
    if (context == null || !_canShowInternetRestoredModal()) {
      return;
    }

    _isTransitionModalShowing = true;
    _activeTransitionModal = _ConnectionTransitionKind.internetRestored;

    ConnectionTransitionAction? action;
    try {
      action = await ConnectionTransitionModal.showInternetRestored(context);
    } finally {
      _isTransitionModalShowing = false;
      _activeTransitionModal = null;
    }

    if (!mounted) {
      return;
    }

    switch (action) {
      case ConnectionTransitionAction.stayOffline:
        _userChoseStayOffline = true;
        return;
      case ConnectionTransitionAction.goOnline:
        await _goOnlineFromOfflineMode();
        return;
      case ConnectionTransitionAction.stayOnline:
      case ConnectionTransitionAction.goOffline:
      case null:
        return;
    }
  }

  Future<void> _showInternetLostModal() async {
    final context = appNavigatorKey.currentContext;
    if (context == null || !_canShowInternetLostModal()) {
      return;
    }

    _isTransitionModalShowing = true;
    _activeTransitionModal = _ConnectionTransitionKind.internetLost;

    ConnectionTransitionAction? action;
    try {
      action = await ConnectionTransitionModal.showInternetLost(context);
    } finally {
      _isTransitionModalShowing = false;
      _activeTransitionModal = null;
    }

    if (!mounted) {
      return;
    }

    switch (action) {
      case ConnectionTransitionAction.stayOnline:
        _userChoseStayOnline = true;
        _showReconnectLoadingUntilOnline();
        return;
      case ConnectionTransitionAction.goOffline:
        await _goOfflineFromOnlineMode();
        return;
      case ConnectionTransitionAction.stayOffline:
      case ConnectionTransitionAction.goOnline:
      case null:
        return;
    }
  }

  Future<void> _goOnlineFromOfflineMode() async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _userChoseStayOffline = false;
    PreHikeLoginTransition.start();

    await navigator.push<Object?>(
      MaterialPageRoute(
        builder: (_) => PreHikeLoadingScreen(
          loginFuture: Future<void>.value(),
          nextRoute: AppRoutes.login,
          resolveNextRoute: _resolveGoOnlineRoute,
        ),
      ),
    );
  }

  Future<void> _goOfflineFromOnlineMode() async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _userChoseStayOnline = false;
    _previousAuthenticatedUserId = FirebaseAuth.instance.currentUser?.uid;
    _appModeProvider.rememberPreviousOnlineRoute(
      appRouteObserver.currentRouteName,
    );
    _appModeProvider.clearSignInAfterOfflineModeRequest();
    _appModeProvider.enableOfflineMode();
    PreHikeLoginTransition.start();

    await navigator.push<Object?>(
      MaterialPageRoute(
        builder: (_) => PreHikeLoadingScreen(
          loginFuture: Future<void>.value(),
          nextRoute: AppRoutes.home,
        ),
      ),
    );
  }

  Future<String> _resolveGoOnlineRoute() async {
    final returnRoute = _onlineReturnRoute();
    final hasValidSavedSession = await _hasValidSavedSession();

    _appModeProvider.clearSignInAfterOfflineModeRequest();
    _appModeProvider.disableOfflineMode();

    if (hasValidSavedSession) {
      return returnRoute;
    }

    _appModeProvider.requestSignInAfterOfflineMode();
    return AppRoutes.loginWithRedirect(returnRoute);
  }

  String _onlineReturnRoute() {
    final normalized = AppRoutes.normalizeLocation(
      _appModeProvider.previousOnlineRoute,
    );
    final path = Uri.parse(normalized).path;

    if (path == AppRoutes.login ||
        path == AppRoutes.signup ||
        path == '/forgot-password') {
      return AppRoutes.home;
    }

    return normalized;
  }

  Future<bool> _hasValidSavedSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logReconnect('no saved Firebase user found');
      return false;
    }

    final previousUserId = _previousAuthenticatedUserId;
    if (previousUserId != null && user.uid != previousUserId) {
      _logReconnect('saved Firebase user does not match previous account');
      return false;
    }

    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        _logReconnect('Firebase user disappeared during reload');
        return false;
      }

      if (previousUserId != null && refreshedUser.uid != previousUserId) {
        _logReconnect(
          'refreshed Firebase user does not match previous account',
        );
        return false;
      }

      await refreshedUser.getIdToken(true);
      _previousAuthenticatedUserId = refreshedUser.uid;
      _logReconnect('saved Firebase session verified');
      return true;
    } on FirebaseAuthException catch (error) {
      if (_isInvalidSavedSessionError(error)) {
        _logReconnect('saved Firebase session is invalid: ${error.code}');
        return false;
      }

      final stillHasSavedUser = FirebaseAuth.instance.currentUser != null;
      _logReconnect(
        'Firebase session validation was inconclusive: ${error.code}',
      );
      return stillHasSavedUser;
    } catch (error) {
      final stillHasSavedUser = FirebaseAuth.instance.currentUser != null;
      _logReconnect(
        'Firebase session validation failed with ${error.runtimeType}',
      );
      return stillHasSavedUser;
    }
  }

  bool _isInvalidSavedSessionError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-user-token':
      case 'user-token-expired':
      case 'user-disabled':
      case 'user-not-found':
        return true;
      default:
        return false;
    }
  }

  void _showReconnectLoadingUntilOnline() {
    final context = appNavigatorKey.currentContext;
    if (context == null || _isReconnectLoadingShowing) {
      return;
    }

    _isReconnectLoadingShowing = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const ConnectionReconnectingDialog(),
      ).whenComplete(() {
        _isReconnectLoadingShowing = false;
      }),
    );

    unawaited(_waitForInternetToReturn());
  }

  Future<void> _waitForInternetToReturn() async {
    while (mounted && _userChoseStayOnline && _appModeProvider.isOnlineMode) {
      final status = await _connectivityService.checkInternetStatus(
        attempts: 2,
      );

      if (!mounted) {
        return;
      }

      if (status == InternetConnectionStatus.online) {
        _lastKnownConnectionState = InternetConnectionStatus.online;
        _userChoseStayOnline = false;
        _dismissReconnectLoadingIfShowing();
        return;
      }

      await Future<void>.delayed(_reconnectPollInterval);
    }
  }

  void _dismissStaleTransitionModal(InternetConnectionStatus status) {
    if (!_isTransitionModalShowing || _activeTransitionModal == null) {
      return;
    }

    final restoredModalIsStale =
        _activeTransitionModal == _ConnectionTransitionKind.internetRestored &&
        status == InternetConnectionStatus.offline;
    final lostModalIsStale =
        _activeTransitionModal == _ConnectionTransitionKind.internetLost &&
        status == InternetConnectionStatus.online;

    if (!restoredModalIsStale && !lostModalIsStale) {
      return;
    }

    _isTransitionModalShowing = false;
    _activeTransitionModal = null;
    final navigator = appNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  void _dismissReconnectLoadingIfShowing() {
    if (!_isReconnectLoadingShowing) {
      return;
    }

    _isReconnectLoadingShowing = false;
    final navigator = appNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  void _logReconnect(String message) {
    debugPrint('[InternetReconnect] $message');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
