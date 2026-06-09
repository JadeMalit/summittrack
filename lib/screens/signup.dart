import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signin.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  bool hidePass = true;
  bool hideConfirm = true;

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

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    /// EMPTY FIELD CHECK
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    /// PASSWORD MATCH CHECK
    if (passwordController.text.trim() != confirmController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => loading = true);

      /// CREATE ACCOUNT
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      /// SAVE DISPLAY NAME
      await userCredential.user!
          .updateDisplayName(nameController.text.trim());
      await userCredential.user!.reload();

      /// SAVE USER DATA TO FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      /// SUCCESS MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      /// GO TO SIGN IN WITH ANIMATION UPON SUCCESS
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SignInScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const beginOffset = Offset(-1.0, 0.0); // Left to Right
              const endOffset = Offset.zero;
              const curve = Curves.easeInOutCubic;

              final tween = Tween(begin: beginOffset, end: endOffset)
                  .chain(CurveTween(curve: curve));
              final offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong.";

      if (e.code == 'email-already-in-use') {
        message = "Email is already registered.";
      } else if (e.code == 'weak-password') {
        message = "Password should be at least 6 characters.";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email.";
      } else if (e.code == 'network-request-failed') {
        message = "Check your internet connection.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
        color: Colors.grey[600],
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/signin.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 110,
                    ),
                  ),
                  const SizedBox(height: 5),

                  /// Gradient Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ShaderMask(
                      shaderCallback: (bounds) => gradient.createShader(bounds),
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
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration("Enter your full name"),
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
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration("Enter your email"),
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// PASSWORD
                  _labelStyle("Password"),
                  const SizedBox(height: 8),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: passwordController,
                      obscureText: hidePass,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration("Enter your password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePass ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => hidePass = !hidePass);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// CONFIRM PASSWORD
                  _labelStyle("Confirm Password"),
                  const SizedBox(height: 8),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: confirmController,
                      obscureText: hideConfirm,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration("Confirm your password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            hideConfirm ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => hideConfirm = !hideConfirm);
                          },
                        ),
                      ),
                    ),
                  ),
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
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => 
                                  const SignInScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                // Left to Right sliding configuration
                                const beginOffset = Offset(-1.0, 0.0);
                                const endOffset = Offset.zero;
                                const curve = Curves.easeInOutCubic;

                                final tween = Tween(begin: beginOffset, end: endOffset)
                                    .chain(CurveTween(curve: curve));
                                final offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          );
                        },
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: SizedBox(
                            width: 240,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: signUp,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}