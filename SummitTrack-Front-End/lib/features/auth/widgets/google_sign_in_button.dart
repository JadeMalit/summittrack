import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/google_auth_service.dart';
import '../screens/SignIN_SignUP/pre_hike_loading_screen.dart';

class GoogleAuthButton extends StatefulWidget {
  const GoogleAuthButton({
    super.key,
    required this.nextRoute,
    this.isBusy = false,
    this.text = 'Continue with Google',
    this.minimumDuration = const Duration(seconds: 2),
    this.showLoadingScreenDuringAuth = false,
    this.onLoadingChanged,
    this.onAuthFlowStart,
    this.onAuthFlowFinish,
  });

  final String nextRoute;
  final bool isBusy;
  final String text;
  final Duration minimumDuration;
  final bool showLoadingScreenDuringAuth;
  final ValueChanged<bool>? onLoadingChanged;
  final VoidCallback? onAuthFlowStart;
  final VoidCallback? onAuthFlowFinish;

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  static const _googleSignInCancelledMessage =
      'Google sign-in was cancelled. Please try again.';

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  bool get _isButtonBusy => widget.isBusy || _isLoading;

  Future<void> _continueWithGoogle() async {
    if (_isButtonBusy) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).clearSnackBars();
    _setLoading(true);
    widget.onAuthFlowStart?.call();

    try {
      await _signInOrRegisterWithGoogle();

      if (!mounted || FirebaseAuth.instance.currentUser == null) {
        return;
      }

      if (widget.showLoadingScreenDuringAuth) {
        await _showLoadingScreenForGoogleAuth();
        return;
      }

      await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => PreHikeLoadingScreen(
            loginFuture: Future<void>.value(),
            nextRoute: widget.nextRoute,
            minimumDuration: widget.minimumDuration,
          ),
        ),
      );
    } on GoogleAuthServiceException catch (error) {
      if (error.isCancellation) {
        return;
      }

      _showGoogleAuthError(error);
    } on FirebaseAuthException catch (error) {
      if (_isFirebaseAuthCancellation(error)) {
        return;
      }

      _showGoogleAuthError(error);
    } catch (error) {
      _showGoogleAuthError(error);
    } finally {
      widget.onAuthFlowFinish?.call();
      _setLoading(false);
    }
  }

  Future<void> _showLoadingScreenForGoogleAuth() async {
    if (!mounted || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    final authError = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => PreHikeLoadingScreen(
          loginFuture: Future<void>.value(),
          nextRoute: widget.nextRoute,
          minimumDuration: widget.minimumDuration,
        ),
      ),
    );

    if (authError != null && !_isGoogleAuthCancellation(authError)) {
      _showGoogleAuthError(authError);
    }
  }

  Future<void> _signInOrRegisterWithGoogle() {
    return _googleAuthService.signInOrRegisterWithGoogle().then<void>((_) {});
  }

  void _showGoogleAuthError(Object error) {
    if (error is GoogleAuthServiceException) {
      _showError(error.message);
      return;
    }

    if (error is FirebaseAuthException) {
      _showError(_googleAuthMessageForFirebaseError(error));
      return;
    }

    _showError('Unable to connect with Google right now.');
  }

  String _googleAuthMessageForFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
      case 'cancelled-popup-request':
      case 'user-cancelled':
      case 'user_cancelled':
        return _googleSignInCancelledMessage;
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'popup-blocked':
        return 'Your browser blocked the Google sign-in popup. Please allow popups and try again.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled yet. Please enable the Google provider in Firebase Authentication.';
      default:
        return 'Unable to connect with Google right now. Please try again.';
    }
  }

  bool _isGoogleAuthCancellation(Object error) {
    if (error is GoogleAuthServiceException) {
      return error.isCancellation;
    }

    if (error is FirebaseAuthException) {
      return _isFirebaseAuthCancellation(error);
    }

    return false;
  }

  bool _isFirebaseAuthCancellation(FirebaseAuthException error) {
    switch (error.code) {
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
      case 'cancelled-popup-request':
      case 'user-cancelled':
      case 'user_cancelled':
        return true;
      default:
        return false;
    }
  }

  void _setLoading(bool isLoading) {
    if (!mounted || _isLoading == isLoading) {
      return;
    }

    setState(() => _isLoading = isLoading);
    widget.onLoadingChanged?.call(isLoading);
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleSignInButton(
      text: widget.text,
      isLoading: _isLoading,
      onPressed: _isButtonBusy ? null : _continueWithGoogle,
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isEnabled ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.96),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.82),
            foregroundColor: const Color(0xFF202124),
            disabledForegroundColor: const Color(0xFF6A6A6A),
            side: BorderSide(
              color: const Color(0xFFE1E9D9).withValues(alpha: 0.95),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('google-loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : Row(
                    key: const ValueKey('google-content'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GoogleLogo(size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.16;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    void drawArc(double startDegrees, double sweepDegrees, Color color) {
      paint.color = color;
      canvas.drawArc(
        rect,
        startDegrees * math.pi / 180,
        sweepDegrees * math.pi / 180,
        false,
        paint,
      );
    }

    drawArc(-38, 82, _blue);
    drawArc(44, 74, _green);
    drawArc(118, 72, _yellow);
    drawArc(190, 104, _red);

    paint
      ..color = _blue
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.88, size.height * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
