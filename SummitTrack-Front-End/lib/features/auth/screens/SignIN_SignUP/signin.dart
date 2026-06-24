import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_routes.dart';
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

  bool loading = false;
  bool hidePass = true;
  bool _didPrecacheAssets = false;
  bool _navigatingToRegister = false;
  String? errorMessage;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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
    emailController.dispose();
    passwordController.dispose();
    _controller.dispose();
    super.dispose();
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
    if (_navigatingToRegister || loading) return;

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

  Future<void> signIn() async {
    if (loading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    FocusScope.of(context).unfocus();
    _clearError();

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
            nextRoute: widget.redirectTo,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Colors.lightGreenAccent, Colors.green],
    );

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
                                  height: 150,
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
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

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
                                  onChanged: (_) => _clearError(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                  onChanged: (_) => _clearError(),
                                  obscureText: hidePass,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _inputDecoration(
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
                                  onPressed: () {
                                    _clearError();
                                    Navigator.pushNamed(context, '/forgot-password');
                                  },
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an Account? ",
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
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SizedBox(
                                      width: 220,
                                      height: 60,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.lightGreen,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        onPressed: loading ? null : signIn,
                                        child: Text(
                                          "LOGIN",
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
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