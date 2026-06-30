import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/video_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase's signed-out client API still needs this check to avoid
      // offering password resets for Google-only accounts.
      final signInMethods = await FirebaseAuth.instance
          // ignore: deprecated_member_use
          .fetchSignInMethodsForEmail(email);
      final isGoogleOnlyAccount =
          signInMethods.contains('google.com') &&
          !signInMethods.contains('password');

      if (isGoogleOnlyAccount) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This email is connected with Google. Please sign in using Continue with Google instead.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent! Please check your email.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Please check your internet connection and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goBackToSignIn() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VideoBackground.fallbackBackgroundColor,
      body: VideoBackground(
        videoAssetPath: 'assets/videos/login_background.mp4',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Summit Track Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'FORGOT PASSWORD',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9CCC65),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter your email and we\'ll send you a link to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          cursorColor: const Color(0xFF4CAF50),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(230, 255, 255, 255),
                            hintText: 'Enter your email',
                            hintStyle: const TextStyle(color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 20.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9CCC65), Color(0xFF7CB342)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendResetLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'SEND RESET LINK',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white38)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white38)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: _goBackToSignIn,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF9CCC65),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        child: const Text(
                          'BACK TO SIGN IN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    );
  }
}
