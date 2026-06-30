import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_routes.dart';
import '../../helpers/gmail_email_validator.dart';
import '../../services/google_auth_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/video_background.dart';

class RegistrationAuthFlow {
  static bool isActive = false;

  static void start() {
    isActive = true;
  }

  static void finish() {
    isActive = false;
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.redirectTo = AppRoutes.home});

  final String redirectTo;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final nameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmFocusNode = FocusNode();

  static const _inputTextColor = Color(0xFF1F1F1F);
  static const _inputHintColor = Color(0xFF6A6A6A);
  static const _inputIconColor = Color(0xFF4F4F4F);
  static const _inputCursorColor = Color(0xFF4CAF50);

  bool loading = false;
  bool googleLoading = false;
  bool hidePass = true;
  bool hideConfirm = true;
  bool _didPrecacheAssets = false;
  bool _navigatingToSignIn = false;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isBusy => loading || googleLoading;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(VideoBackground.preload('assets/videos/login_background.mp4'));
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (_isBusy) return;

    final email = normalizeGmailEmail(emailController.text);
    final password = passwordController.text;
    final confirmPassword = confirmController.text;
    final emailValidationMessage = validateGmailEmail(email);

    /// EMPTY FIELD CHECK
    if (nameController.text.trim().isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        emailError = email.isEmpty ? null : emailValidationMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (emailValidationMessage != null) {
      setState(() => emailError = emailValidationMessage);
      return;
    }

    final passwordValidationMessage = _validatePassword(password);
    if (passwordValidationMessage != null) {
      setState(() {
        emailError = null;
        passwordError = passwordValidationMessage;
        confirmPasswordError = null;
      });
      return;
    }

    /// PASSWORD MATCH CHECK
    final confirmValidationMessage = _validateConfirmPassword(
      password,
      confirmPassword,
    );
    if (confirmValidationMessage != null) {
      setState(() {
        emailError = null;
        passwordError = null;
        confirmPasswordError = confirmValidationMessage;
      });
      return;
    }

    var createdAuthUser = false;

    try {
      setState(() {
        loading = true;
        emailError = null;
        passwordError = null;
        confirmPasswordError = null;
      });
      RegistrationAuthFlow.start();

      /// CREATE ACCOUNT
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      createdAuthUser = true;

      /// SAVE DISPLAY NAME
      await userCredential.user!.updateDisplayName(nameController.text.trim());
      await userCredential.user!.reload();

      /// SAVE USER DATA TO FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': nameController.text.trim(),
            'email': email,
            'authProvider': 'password',
            'providers': ['password'],
            'emailVerified': userCredential.user!.emailVerified,
            'createdAt': Timestamp.now(),
          });

      /// CREATE ACCOUNT signs the user in automatically, so sign out before
      /// returning them to the sign-in screen.
      await FirebaseAuth.instance.signOut();
      createdAuthUser = false;

      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        _clearRegisterForm();
      });

      /// SUCCESS MESSAGE
      await _showAccountCreatedDialog();

      /// GO TO SIGN IN UPON SUCCESS
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on FirebaseAuthException catch (e) {
      if (createdAuthUser) {
        await FirebaseAuth.instance.signOut();
        createdAuthUser = false;
      }

      String message = "Something went wrong.";

      if (e.code == 'email-already-in-use') {
        message = "Email is already registered.";
      } else if (e.code == 'weak-password') {
        message = "Password must meet the password requirements.";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email.";
      } else if (e.code == 'network-request-failed') {
        message = "Check your internet connection.";
      }

      if (!mounted) {
        return;
      }

      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (createdAuthUser) {
        await FirebaseAuth.instance.signOut();
        createdAuthUser = false;
      }

      if (!mounted) {
        return;
      }

      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      RegistrationAuthFlow.finish();
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).clearSnackBars();

    try {
      setState(() => googleLoading = true);
      RegistrationAuthFlow.start();

      await _googleAuthService.signInOrRegisterWithGoogle();

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(widget.redirectTo, (route) => false);
    } on GoogleAuthServiceException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to connect with Google right now."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      RegistrationAuthFlow.finish();
      if (mounted) {
        setState(() => googleLoading = false);
      }
    }
  }

  Future<void> _showAccountCreatedDialog() {
    const successGreen = Color(0xFF4CAF50);
    const softGreen = Color(0xFFEAF7EC);
    const titleColor = Color(0xFF1E3324);
    const bodyColor = Color(0xFF5A675D);

    return showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      barrierDismissible: false,
      barrierLabel: "Account created",
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return PopScope(
          canPop: false,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: softGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: successGreen,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Account Created",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: titleColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Your account has been created successfully. "
                            "Please sign in to continue.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: bodyColor,
                              fontSize: 14.5,
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: successGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(
                                "OK",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scaleAnimation = Tween<double>(
          begin: 0.94,
          end: 1,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }

  void _clearRegisterForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmController.clear();
    emailError = null;
    passwordError = null;
    confirmPasswordError = null;
  }

  String? _validatePassword(String password) {
    final messages = _passwordValidationMessages(password);
    return messages.isEmpty ? null : messages.join('\n');
  }

  List<String> _passwordValidationMessages(String password) {
    final messages = <String>[];

    if (password.length < 8) {
      messages.add("Password must be at least 8 characters.");
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      messages.add("Password must contain at least one uppercase letter.");
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      messages.add("Password must contain at least one number.");
    }

    if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
      messages.add("Password must contain at least one special character.");
    }

    if (RegExp(r'\s').hasMatch(password)) {
      messages.add("Spaces are not allowed in password.");
    }

    if (RegExp(r'^[A-Za-z]+$').hasMatch(password)) {
      messages.add("Password cannot be all letters only.");
    }

    if (RegExp(r'^\d+$').hasMatch(password)) {
      messages.add("Password cannot be all numbers only.");
    }

    return messages;
  }

  String? _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return null;
    }

    return password == confirmPassword ? null : "Passwords do not match.";
  }

  void _updatePasswordValidation(String password) {
    final validationMessage = password.isEmpty
        ? null
        : _validatePassword(password);
    final confirmValidationMessage = _validateConfirmPassword(
      password,
      confirmController.text,
    );

    if (passwordError != validationMessage ||
        confirmPasswordError != confirmValidationMessage) {
      setState(() {
        passwordError = validationMessage;
        confirmPasswordError = confirmValidationMessage;
      });
    }
  }

  void _updateConfirmPasswordValidation(String confirmPassword) {
    final validationMessage = _validateConfirmPassword(
      passwordController.text,
      confirmPassword,
    );

    if (confirmPasswordError != validationMessage) {
      setState(() => confirmPasswordError = validationMessage);
    }
  }

  Future<void> _goToSignIn() async {
    if (_navigatingToSignIn || _isBusy) return;

    _navigatingToSignIn = true;
    FocusScope.of(context).unfocus();
    unawaited(VideoBackground.preload('assets/videos/login_background.mp4'));

    try {
      await Navigator.pushReplacementNamed(
        context,
        AppRoutes.loginWithRedirect(widget.redirectTo),
      );
    } finally {
      _navigatingToSignIn = false;
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget _labelStyle(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Colors.lightGreenAccent, Colors.green],
    );

    return PopScope(
      canPop: !_isBusy,
      child: Scaffold(
        backgroundColor: VideoBackground.fallbackBackgroundColor,
        body: VideoBackground(
          videoAssetPath: 'assets/videos/register_background.mp4',
          overlayColor: const Color(0x80000000),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Image.asset(
                              "assets/images/logo.jpg",
                              height: 110,
                            ),
                          ),
                          const SizedBox(height: 5),

                          /// Gradient Title
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  gradient.createShader(bounds),
                              child: Text(
                                "Pre-Hike",
                                style: GoogleFonts.raleway(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          /// FULL NAME
                          _labelStyle("Full Name"),
                          const SizedBox(height: 8),
                          SlideTransition(
                            position: _slideAnimation,
                            child: TextField(
                              controller: nameController,
                              focusNode: nameFocusNode,
                              textInputAction: TextInputAction.next,
                              cursorColor: _inputCursorColor,
                              onSubmitted: (_) => emailFocusNode.requestFocus(),
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              style: _inputTextStyle(),
                              decoration: _inputDecoration(
                                "Enter your full name",
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          /// EMAIL
                          _labelStyle("Email"),
                          const SizedBox(height: 8),
                          SlideTransition(
                            position: _slideAnimation,
                            child: TextField(
                              controller: emailController,
                              focusNode: emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              cursorColor: _inputCursorColor,
                              onChanged: (value) {
                                final validationMessage = validateGmailEmail(
                                  value,
                                );
                                if (emailError != validationMessage) {
                                  setState(() {
                                    emailError = validationMessage;
                                  });
                                }
                              },
                              onSubmitted: (_) =>
                                  passwordFocusNode.requestFocus(),
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              style: _inputTextStyle(),
                              decoration: _inputDecoration("Enter your email"),
                            ),
                          ),
                          if (emailError != null) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                emailError!,
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 15),

                          /// PASSWORD
                          _labelStyle("Password"),
                          const SizedBox(height: 8),
                          SlideTransition(
                            position: _slideAnimation,
                            child: TextField(
                              controller: passwordController,
                              focusNode: passwordFocusNode,
                              obscureText: hidePass,
                              onChanged: _updatePasswordValidation,
                              textInputAction: TextInputAction.next,
                              cursorColor: _inputCursorColor,
                              onSubmitted: (_) =>
                                  confirmFocusNode.requestFocus(),
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
                                        setState(() => hidePass = !hidePass);
                                      },
                                    ),
                                  ),
                            ),
                          ),
                          if (passwordError != null) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                passwordError!,
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 15),

                          /// CONFIRM PASSWORD
                          _labelStyle("Confirm Password"),
                          const SizedBox(height: 8),
                          SlideTransition(
                            position: _slideAnimation,
                            child: TextField(
                              controller: confirmController,
                              focusNode: confirmFocusNode,
                              obscureText: hideConfirm,
                              onChanged: _updateConfirmPasswordValidation,
                              textInputAction: TextInputAction.done,
                              cursorColor: _inputCursorColor,
                              onSubmitted: (_) => signUp(),
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              style: _inputTextStyle(),
                              decoration:
                                  _inputDecoration(
                                    "Confirm your password",
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        hideConfirm
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => hideConfirm = !hideConfirm,
                                        );
                                      },
                                    ),
                                  ),
                            ),
                          ),
                          if (confirmPasswordError != null) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                confirmPasswordError!,
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          /// REGISTER LINK WITH LEFT-TO-RIGHT SLIDE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an Account? ",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: _goToSignIn,
                                child: Text(
                                  "Sign In",
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          /// SIGN UP BUTTON
                          loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SizedBox(
                                    width: 240,
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
                                      onPressed: _isBusy ? null : signUp,
                                      child: Text(
                                        "REGISTER",
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 14),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: GoogleSignInButton(
                                isLoading: googleLoading,
                                onPressed: _isBusy ? null : _continueWithGoogle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
