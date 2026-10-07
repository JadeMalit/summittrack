import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/layout/app_responsive.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/state/app_mode_provider.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/offline_mode_dialog.dart';
import '../../widgets/video_background.dart';
import 'pre_hike_loading_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.redirectTo = AppRoutes.home});

  final String redirectTo;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  static const _inputTextColor = Color(0xFF1F1F1F);
  static const _inputHintColor = Color(0xFF6A6A6A);
  static const _inputIconColor = Color(0xFF4F4F4F);
  static const _inputCursorColor = Color(0xFF4CAF50);
  static const _connectivityChangeDebounce = Duration(milliseconds: 700);
  static const _offlineDialogDebounce = Duration(seconds: 2);

  bool loading = false;
  bool _isGoogleLoading = false;
  bool hidePass = true;
  bool _didPrecacheAssets = false;
  bool _navigatingToRegister = false;
  bool _isCheckingConnectivity = false;
  bool _isOfflineDialogShowing = false;
  InternetConnectionStatus _connectionStatus =
      InternetConnectionStatus.checking;
  bool _initialConnectivityCheckFinished = false;
  bool _isAppStarting = true;
  String? errorMessage;

  late final AppModeProvider _appModeProvider;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  StreamSubscription<void>? _connectivitySubscription;
  Timer? _connectivityTimer;
  Timer? _connectivityChangeDebounceTimer;
  Timer? _offlineDialogTimer;
  int _connectivityCheckSerial = 0;
  bool? _pendingConnectivityStartupCheck;

  bool get _isBusy => loading || _isGoogleLoading;

  bool get _isCurrentSignInRoute {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return false;
    }

    final routeName = route.settings.name;
    final path = Uri.parse(AppRoutes.normalizeLocation(routeName)).path;
    return path == AppRoutes.login;
  }

  @override
  void initState() {
    super.initState();

    _appModeProvider = AppModeProvider.instance;
    _appModeProvider.addListener(_handleAppModeChanged);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      unawaited(
        VideoBackground.preload('assets/videos/register_background.mp4'),
      );
      _scheduleInitialConnectivityCheck();
    });

    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((_) {
          _logConnectivity('connectivity listener event received');
          _scheduleConnectivityCheckAfterChange();
        });

    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_checkConnectionAndMaybeShowDialog());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didPrecacheAssets) return;
    _didPrecacheAssets = true;
    unawaited(
      precacheImage(const AssetImage("assets/images/logo.jpg"), context),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();
    _connectivityChangeDebounceTimer?.cancel();
    _offlineDialogTimer?.cancel();
    _appModeProvider.removeListener(_handleAppModeChanged);
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleAppModeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  void _scheduleInitialConnectivityCheck() {
    _logConnectivity('app startup internet check started');
    _isAppStarting = true;
    _cancelPendingOfflineDialog();
    _setConnectionStatus(InternetConnectionStatus.checking);
    _logConnectivity('status checking, modal blocked');
    unawaited(_checkConnectionAndMaybeShowDialog(isStartupCheck: true));
  }

  void _scheduleConnectivityCheckAfterChange() {
    if (!mounted || !_initialConnectivityCheckFinished || _isAppStarting) {
      _logConnectivity(
        'connectivity change ignored while startup check is active',
      );
      return;
    }

    _connectivityChangeDebounceTimer?.cancel();
    _connectivityChangeDebounceTimer = Timer(_connectivityChangeDebounce, () {
      if (!mounted || !_initialConnectivityCheckFinished || _isAppStarting) {
        _logConnectivity('debounced connectivity check skipped during startup');
        return;
      }

      unawaited(_checkConnectionAndMaybeShowDialog());
    });
  }

  Future<void> _checkConnectionAndMaybeShowDialog({
    bool isStartupCheck = false,
  }) async {
    if (_isBusy) {
      _logConnectivity('connectivity check skipped while auth flow is busy');
      return;
    }

    final checkSerial = ++_connectivityCheckSerial;

    if (_isCheckingConnectivity) {
      _pendingConnectivityStartupCheck =
          (_pendingConnectivityStartupCheck ?? false) || isStartupCheck;
      _logConnectivity(
        'connectivity check queued because another check is running',
      );
      return;
    }

    _isCheckingConnectivity = true;
    final previousStatus = _connectionStatus;
    _setConnectionStatus(InternetConnectionStatus.checking);
    _logConnectivity('status checking, modal blocked');
    _cancelPendingOfflineDialog();

    try {
      final status = await _connectivityService.checkInternetStatus(
        isStartupCheck: isStartupCheck,
      );

      if (!mounted || checkSerial != _connectivityCheckSerial) {
        return;
      }

      if (status == InternetConnectionStatus.online) {
        _initialConnectivityCheckFinished = true;
        _isAppStarting = false;
        _setConnectionStatus(status);
        _logConnectivity('offline confirmed false');
        _handleConfirmedOnline(previousStatus: previousStatus);
        return;
      }

      _initialConnectivityCheckFinished = true;
      _isAppStarting = false;
      _logConnectivity('offline confirmed true');
      _setConnectionStatus(InternetConnectionStatus.offline);
      _scheduleOfflineDialogCheck(checkSerial);
    } finally {
      if (mounted) {
        _isCheckingConnectivity = false;

        if (checkSerial != _connectivityCheckSerial) {
          final pendingStartupCheck = _pendingConnectivityStartupCheck ?? false;
          _pendingConnectivityStartupCheck = null;
          unawaited(
            _checkConnectionAndMaybeShowDialog(
              isStartupCheck: pendingStartupCheck,
            ),
          );
        }
      }
    }
  }

  void _setConnectionStatus(InternetConnectionStatus status) {
    _connectionStatus = status;
  }

  void _handleConfirmedOnline({
    InternetConnectionStatus? previousStatus,
    bool dismissDialog = true,
  }) {
    final hadPendingOfflineDialog = _offlineDialogTimer != null;
    final hadOfflineState =
        previousStatus == InternetConnectionStatus.offline ||
        _connectionStatus == InternetConnectionStatus.offline ||
        hadPendingOfflineDialog ||
        _isOfflineDialogShowing ||
        _appModeProvider.isOfflineMode;

    _setConnectionStatus(InternetConnectionStatus.online);
    if (hadPendingOfflineDialog) {
      _logConnectivity('modal show cancelled because internet is available');
    }
    _cancelPendingOfflineDialog();
    _connectivityChangeDebounceTimer?.cancel();
    _connectivityChangeDebounceTimer = null;

    if (hadOfflineState) {
      _logConnectivity('internet restored');
    }

    if (dismissDialog) {
      _dismissOfflineDialogIfShowing();
    }
  }

  void _scheduleOfflineDialogCheck(int checkSerial) {
    _offlineDialogTimer?.cancel();
    if (_isOfflineDialogShowing) {
      _logConnectivity('modal already showing, skipped');
      return;
    }

    if (_connectionStatus == InternetConnectionStatus.checking) {
      _logConnectivity('status checking, modal blocked');
      return;
    }

    _logConnectivity('modal show requested');
    _offlineDialogTimer = Timer(_offlineDialogDebounce, () {
      _offlineDialogTimer = null;
      if (!_canAttemptOfflineDialog(checkSerial)) {
        _logConnectivity('modal show cancelled before final confirmation');
        return;
      }

      unawaited(_confirmOfflineAndShowDialog(checkSerial: checkSerial));
    });
  }

  void _cancelPendingOfflineDialog() {
    _offlineDialogTimer?.cancel();
    _offlineDialogTimer = null;
  }

  Future<void> _confirmOfflineAndShowDialog({required int checkSerial}) async {
    if (!_canAttemptOfflineDialog(checkSerial) ||
        _connectionStatus != InternetConnectionStatus.offline) {
      _logConnectivity('modal show cancelled before final confirmation');
      return;
    }

    _setConnectionStatus(InternetConnectionStatus.checking);
    _logConnectivity('status checking, modal blocked');
    final status = await _connectivityService.checkInternetStatus(attempts: 2);

    if (!mounted || checkSerial != _connectivityCheckSerial) {
      _logConnectivity('modal show cancelled because check is stale');
      return;
    }

    if (status == InternetConnectionStatus.online) {
      _logConnectivity('modal show cancelled because internet is available');
      _handleConfirmedOnline(previousStatus: InternetConnectionStatus.offline);
      return;
    }

    _setConnectionStatus(InternetConnectionStatus.offline);
    if (!_canAttemptOfflineDialog(checkSerial)) {
      _logConnectivity('modal show cancelled before display');
      return;
    }

    _isOfflineDialogShowing = true;
    OfflineModeDialogAction? action;

    try {
      action = await OfflineModeDialog.show(
        context,
        onStayOnline: _canCloseOfflineDialogFromStayOnline,
      );
    } finally {
      if (mounted) {
        _isOfflineDialogShowing = false;
      }
    }

    if (!mounted || _connectionStatus == InternetConnectionStatus.online) {
      return;
    }

    if (action == OfflineModeDialogAction.useOfflineMode) {
      await _startOfflineHike();
    }
  }

  Future<bool> _canCloseOfflineDialogFromStayOnline() async {
    final status = await _connectivityService.checkInternetStatus(attempts: 2);

    if (!mounted) {
      return false;
    }

    if (status == InternetConnectionStatus.online) {
      _handleConfirmedOnline(
        previousStatus: InternetConnectionStatus.offline,
        dismissDialog: false,
      );
      return true;
    }

    _setConnectionStatus(InternetConnectionStatus.offline);
    _logConnectivity('stay online kept modal open because still offline');
    return false;
  }

  bool _canAttemptOfflineDialog(int checkSerial) {
    return mounted &&
        checkSerial == _connectivityCheckSerial &&
        _initialConnectivityCheckFinished &&
        !_isAppStarting &&
        _connectionStatus == InternetConnectionStatus.offline &&
        _isCurrentSignInRoute &&
        !_appModeProvider.isOfflineMode &&
        !_isOfflineDialogShowing;
  }

  void _dismissOfflineDialogIfShowing() {
    if (!_isOfflineDialogShowing || !mounted) {
      return;
    }

    _isOfflineDialogShowing = false;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop(OfflineModeDialogAction.stayOnline);
    }
  }

  void _logConnectivity(String message) {
    debugPrint('[SignInConnectivity] $message');
  }

  void _clearError() {
    if (errorMessage == null || !mounted) return;

    setState(() => errorMessage = null);
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() => errorMessage = message);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSignInError(Object error) {
    if (error is FirebaseAuthException) {
      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found' ||
          error.code == 'invalid-email') {
        _showError("Incorrect email or password.");
      } else if (error.code == 'network-request-failed') {
        _showError(
          "Unable to sign in right now. Please check your internet connection.",
        );
      } else {
        _showError("Unable to sign in right now. Please try again.");
      }

      return;
    }

    _showError("Unable to sign in right now. Please try again.");
  }

  Future<void> _goToRegister() async {
    if (_navigatingToRegister || _isBusy) return;

    _navigatingToRegister = true;
    FocusScope.of(context).unfocus();
    _clearError();
    unawaited(VideoBackground.preload('assets/videos/register_background.mp4'));

    try {
      await Navigator.pushNamed(
        context,
        AppRoutes.signupWithRedirect(widget.redirectTo),
      );
    } finally {
      _navigatingToRegister = false;
    }
  }

  Future<void> _goToForgotPassword() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();
    _clearError();

    await Navigator.pushNamed(context, '/forgot-password');

    if (!mounted) return;

    emailFocusNode.unfocus();
    passwordFocusNode.unfocus();
  }

  Future<void> signIn() async {
    if (_isBusy) return;

    if (_appModeProvider.isOfflineMode) {
      await _startOfflineHike();
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    FocusScope.of(context).unfocus();
    _clearError();
    _appModeProvider.disableOfflineMode();
    _appModeProvider.clearSignInAfterOfflineModeRequest();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter your email and password.");
      return;
    }

    try {
      setState(() => loading = true);
      PreHikeLoginTransition.start();

      final loginFuture = FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .then<void>((_) {});

      if (!mounted) return;

      final signInError = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => PreHikeLoadingScreen(
            loginFuture: loginFuture,
            nextRoute: AppRoutes.home,
          ),
        ),
      );

      if (!mounted) return;
      if (signInError != null) {
        _showSignInError(signInError);
      }
    } catch (_) {
      PreHikeLoginTransition.finish();
      _showError("Unable to sign in right now. Please try again.");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _startOfflineHike() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();
    _clearError();
    _appModeProvider.clearSignInAfterOfflineModeRequest();
    _appModeProvider.enableOfflineMode();

    try {
      setState(() => loading = true);
      PreHikeLoginTransition.start();

      final offlineStartFuture = Future<void>.value();

      await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => PreHikeLoadingScreen(
            loginFuture: offlineStartFuture,
            nextRoute: AppRoutes.home,
          ),
        ),
      );
    } catch (_) {
      PreHikeLoginTransition.finish();
      _showError("Unable to start offline mode right now. Please try again.");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: _inputHintColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      suffixIconColor: _inputIconColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.green, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.greenAccent, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
      ),
    );
  }

  TextStyle _inputTextStyle() {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: _inputTextColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Colors.lightGreenAccent, Colors.green],
    );
    final isOfflineMode = _appModeProvider.isOfflineMode;
    final compact = AppResponsive.isCompactWidth(context);

    return Scaffold(
      backgroundColor: VideoBackground.fallbackBackgroundColor,
      body: VideoBackground(
        videoAssetPath: 'assets/videos/login_background.mp4',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = constraints.maxHeight > 40
                  ? constraints.maxHeight - 40
                  : constraints.maxHeight;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Image.asset(
                                  "assets/images/logo.jpg",
                                  height: compact ? 124 : 150,
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// Gradient Title
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      gradient.createShader(bounds),
                                  child: Text(
                                    "Pre-Hike",
                                    style: GoogleFonts.raleway(
                                      fontSize: compact ? 34 : 38,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: compact ? 28 : 40),

                              if (isOfflineMode)
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: const _OfflineModeNotice(),
                                )
                              else ...[
                                /// EMAIL
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Email",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: TextField(
                                    controller: emailController,
                                    focusNode: emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    cursorColor: _inputCursorColor,
                                    onChanged: (_) => _clearError(),
                                    onSubmitted: (_) =>
                                        passwordFocusNode.requestFocus(),
                                    onTapOutside: (_) =>
                                        FocusScope.of(context).unfocus(),
                                    style: _inputTextStyle(),
                                    decoration: _inputDecoration(
                                      "Enter your email",
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                /// PASSWORD
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Password",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: TextField(
                                    controller: passwordController,
                                    focusNode: passwordFocusNode,
                                    onChanged: (_) => _clearError(),
                                    obscureText: hidePass,
                                    textInputAction: TextInputAction.done,
                                    cursorColor: _inputCursorColor,
                                    onSubmitted: (_) => signIn(),
                                    onTapOutside: (_) =>
                                        FocusScope.of(context).unfocus(),
                                    style: _inputTextStyle(),
                                    decoration:
                                        _inputDecoration(
                                          "Enter your password",
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              hidePass
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () {
                                              _clearError();
                                              setState(() {
                                                hidePass = !hidePass;
                                              });
                                            },
                                          ),
                                        ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                /// FORGOT PASSWORD
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _goToForgotPassword,
                                    child: Text(
                                      "Forgot Password?",
                                      style: GoogleFonts.poppins(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                /// REGISTER WITH CUSTOM SLIDE & FADE ANIMATION
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      "Don't have an Account?",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _goToRegister,
                                      child: Text(
                                        "Register",
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: SizedBox(
                                          width: isOfflineMode ? 270 : 220,
                                          height: 60,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.lightGreen,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            onPressed: _isBusy
                                                ? null
                                                : isOfflineMode
                                                ? _startOfflineHike
                                                : signIn,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                isOfflineMode
                                                    ? "Start Hike Offline"
                                                    : "LOGIN",
                                                style: GoogleFonts.poppins(
                                                  fontSize: isOfflineMode
                                                      ? 18
                                                      : 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                if (!loading && !isOfflineMode) ...[
                                  const SizedBox(height: 14),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 300,
                                      ),
                                      child: GoogleAuthButton(
                                        isBusy: _isBusy,
                                        nextRoute: AppRoutes.home,
                                        onAuthFlowStart: () {
                                          _appModeProvider
                                              .clearSignInAfterOfflineModeRequest();
                                          PreHikeLoginTransition.start();
                                        },
                                        onAuthFlowFinish:
                                            PreHikeLoginTransition.finish,
                                        onLoadingChanged: (isLoading) {
                                          if (_isGoogleLoading == isLoading) {
                                            return;
                                          }

                                          setState(() {
                                            _isGoogleLoading = isLoading;
                                          });

                                          if (!isLoading) {
                                            unawaited(
                                              _checkConnectionAndMaybeShowDialog(),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OfflineModeNotice extends StatelessWidget {
  const _OfflineModeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.hiking_rounded,
              color: Colors.lightGreenAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Offline Mode',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Limited access only. You can view mountain information from the Home screen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
