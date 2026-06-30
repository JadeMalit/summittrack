import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.user,
    required this.createdUserRecord,
    required this.isNewAuthUser,
  });

  final User user;
  final bool createdUserRecord;
  final bool isNewAuthUser;
}

class GoogleAuthServiceException implements Exception {
  const GoogleAuthServiceException(this.code, this.message, [this.cause]);

  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: const ['email', 'profile']);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Future<GoogleAuthResult> signInOrRegisterWithGoogle() async {
    UserCredential? credential;

    try {
      credential = kIsWeb
          ? await _signInWithGooglePopup()
          : await _signInWithNativeGoogle();

      final user = credential.user;
      if (user == null) {
        throw const GoogleAuthServiceException(
          'missing-user',
          'Google sign-in did not return a user. Please try again.',
        );
      }

      final email = user.email?.trim();
      if (email == null || email.isEmpty) {
        await _safeSignOut();
        throw const GoogleAuthServiceException(
          'missing-email',
          'Your Google account did not share an email address.',
        );
      }

      if (!user.emailVerified) {
        await _safeSignOut();
        throw const GoogleAuthServiceException(
          'email-not-verified',
          'Please use a verified Google email address.',
        );
      }

      final createdUserRecord = await _saveGoogleUser(user);

      return GoogleAuthResult(
        user: user,
        createdUserRecord: createdUserRecord,
        isNewAuthUser: credential.additionalUserInfo?.isNewUser ?? false,
      );
    } on GoogleAuthServiceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    } on FirebaseException catch (error) {
      if (credential?.user != null) {
        await _safeSignOut();
      }

      throw GoogleAuthServiceException(
        error.code,
        'Google sign-in worked, but we could not save your profile. Please try again.',
        error,
      );
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    } catch (error) {
      if (credential?.user != null) {
        await _safeSignOut();
      }

      throw GoogleAuthServiceException(
        'unknown',
        'Unable to connect with Google right now. Please try again.',
        error,
      );
    }
  }

  Future<UserCredential> _signInWithGooglePopup() async {
    final googleProvider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile')
      ..setCustomParameters({'prompt': 'select_account'});

    return _auth.signInWithPopup(googleProvider);
  }

  Future<UserCredential> _signInWithNativeGoogle() async {
    if (!_supportsNativeGoogleSignIn) {
      throw const GoogleAuthServiceException(
        'unsupported-platform',
        'Google sign-in is not available on this platform yet.',
      );
    }

    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const GoogleAuthServiceException(
        'cancelled',
        'Google sign-in was cancelled.',
      );
    }

    await _guardAgainstPasswordOnlyAccount(googleUser.email);

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> _guardAgainstPasswordOnlyAccount(String email) async {
    // This prevents creating a Google account for an email/password-only user.
    // ignore: deprecated_member_use
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    final hasPassword = methods.contains('password');
    final hasGoogle = methods.contains('google.com');

    if (hasPassword && !hasGoogle) {
      await _googleSignIn.signOut();
      throw const GoogleAuthServiceException(
        'email-already-password',
        'This email is already registered with a password. Please sign in with your password or use Forgot Password.',
      );
    }
  }

  Future<bool> _saveGoogleUser(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userModel = UserModel.fromFirebaseUser(user, authProvider: 'google');
    var createdUserRecord = false;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (snapshot.exists) {
        transaction.set(
          userRef,
          userModel.toProviderUpdateMap(),
          SetOptions(merge: true),
        );
      } else {
        createdUserRecord = true;
        transaction.set(userRef, userModel.toCreateMap());
      }
    });

    return createdUserRecord;
  }

  bool get _supportsNativeGoogleSignIn {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  GoogleAuthServiceException _mapFirebaseAuthError(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
      case 'email-already-in-use':
        return GoogleAuthServiceException(
          error.code,
          'This email is already registered with a password. Please sign in with your password or use Forgot Password.',
          error,
        );
      case 'network-request-failed':
        return GoogleAuthServiceException(
          error.code,
          'No internet connection. Please check your network and try again.',
          error,
        );
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
      case 'cancelled-popup-request':
        return GoogleAuthServiceException(
          error.code,
          'Google sign-in was cancelled.',
          error,
        );
      case 'popup-blocked':
        return GoogleAuthServiceException(
          error.code,
          'Your browser blocked the Google sign-in popup. Please allow popups and try again.',
          error,
        );
      case 'operation-not-allowed':
        return GoogleAuthServiceException(
          error.code,
          'Google sign-in is not enabled yet. Please enable the Google provider in Firebase Authentication.',
          error,
        );
      default:
        return GoogleAuthServiceException(
          error.code,
          'Unable to connect with Google right now. Please try again.',
          error,
        );
    }
  }

  GoogleAuthServiceException _mapPlatformError(PlatformException error) {
    switch (error.code) {
      case 'sign_in_canceled':
        return GoogleAuthServiceException(
          error.code,
          'Google sign-in was cancelled.',
          error,
        );
      case 'network_error':
        return GoogleAuthServiceException(
          error.code,
          'No internet connection. Please check your network and try again.',
          error,
        );
      default:
        return GoogleAuthServiceException(
          error.code,
          'Unable to connect with Google right now. Please try again.',
          error,
        );
    }
  }

  Future<void> _safeSignOut() async {
    await _auth.signOut();
    if (!kIsWeb && _supportsNativeGoogleSignIn) {
      await _googleSignIn.signOut();
    }
  }
}
