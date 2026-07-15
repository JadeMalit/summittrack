import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

const Set<String> _googleAuthCancellationCodes = {
  'cancelled',
  'canceled',
  'cancelled-popup-request',
  'popup-closed-by-user',
  'popup_closed_by_user',
  'web-context-cancelled',
  'user-cancelled',
  'user_cancelled',
  'sign_in_canceled',
  'ERROR_ABORTED_BY_USER',
  'missing-user',
};

const _stepFlow = 'flow';
const _stepWebPopup = 'web.signInWithPopup';
const _stepNativeSignOut = 'native.signOutBeforePicker';
const _stepAccountPicker = 'native.accountPicker';
const _stepPasswordAccountGuard = 'firebase.fetchSignInMethodsForEmail';
const _stepGoogleTokens = 'native.googleAuthenticationTokens';
const _stepFirebaseCredential = 'firebase.createGoogleCredential';
const _stepFirebaseCredentialSignIn = 'firebase.signInWithCredential';
const _stepFirestoreProfileSave = 'firestore.saveGoogleUser';

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
  const GoogleAuthServiceException(
    this.code,
    this.message, [
    this.cause,
    this.step,
  ]);

  final String code;
  final String message;
  final Object? cause;
  final String? step;

  bool get isCancellation => _googleAuthCancellationCodes.contains(code);

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
           googleSignIn ??
           GoogleSignIn(
             scopes: const ['email', 'profile'],
             serverClientId: _androidWebClientId,
           );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const String? _androidWebClientId = _googleWebClientId == ''
      ? null
      : _googleWebClientId;
  static const _cancelledMessage =
      'Google sign-in was cancelled. Please try again.';
  static const _androidConfigMessage =
      'Google sign-in is not configured correctly for this app. Please update Firebase Android SHA fingerprints and google-services.json.';

  Future<GoogleAuthResult> signInOrRegisterWithGoogle() async {
    UserCredential? credential;

    try {
      _logGoogleAuthStep(
        _stepFlow,
        'start platform=${kIsWeb ? 'web' : defaultTargetPlatform.name}; '
        'dartDefineServerClientId=${_androidWebClientId == null ? 'not-provided' : 'provided'}',
      );

      credential = kIsWeb
          ? await _signInWithGooglePopup()
          : await _signInWithNativeGoogle();

      final user = credential.user;
      if (user == null) {
        _logGoogleAuthStep(
          _stepFirebaseCredentialSignIn,
          'missing Firebase user',
        );
        throw const GoogleAuthServiceException(
          'missing-user',
          _cancelledMessage,
          null,
          _stepFirebaseCredentialSignIn,
        );
      }

      final email = user.email?.trim();
      if (email == null || email.isEmpty) {
        await _safeSignOut();
        throw const GoogleAuthServiceException(
          'missing-email',
          'Your Google account did not share an email address.',
          null,
          _stepFirebaseCredentialSignIn,
        );
      }

      if (!user.emailVerified) {
        await _safeSignOut();
        throw const GoogleAuthServiceException(
          'email-not-verified',
          'Please use a verified Google email address.',
          null,
          _stepFirebaseCredentialSignIn,
        );
      }

      final createdUserRecord = await _runGoogleAuthStep(
        _stepFirestoreProfileSave,
        () => _saveGoogleUser(user),
      );

      _logGoogleAuthStep(
        _stepFlow,
        'success uidPresent=${user.uid.isNotEmpty}',
      );

      return GoogleAuthResult(
        user: user,
        createdUserRecord: createdUserRecord,
        isNewAuthUser: credential.additionalUserInfo?.isNewUser ?? false,
      );
    } on GoogleAuthServiceException catch (error, stackTrace) {
      _logGoogleAuthFailure(error.step ?? _stepFlow, error, stackTrace);
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      _logGoogleAuthFailure(_stepFlow, error, stackTrace);
      throw _mapFirebaseAuthError(error);
    } on FirebaseException catch (error, stackTrace) {
      _logGoogleAuthFailure(_stepFlow, error, stackTrace);
      if (credential?.user != null) {
        await _safeSignOut();
      }

      throw GoogleAuthServiceException(
        error.code,
        'Google sign-in worked, but we could not save your profile. Please try again.',
        error,
      );
    } on PlatformException catch (error, stackTrace) {
      _logGoogleAuthFailure(_stepFlow, error, stackTrace);
      throw _mapPlatformError(error);
    } catch (error, stackTrace) {
      _logGoogleAuthFailure(_stepFlow, error, stackTrace);
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

    return _runGoogleAuthStep(
      _stepWebPopup,
      () => _auth.signInWithPopup(googleProvider),
    );
  }

  Future<UserCredential> _signInWithNativeGoogle() async {
    if (!_supportsNativeGoogleSignIn) {
      throw const GoogleAuthServiceException(
        'unsupported-platform',
        'Google sign-in is not available on this platform yet.',
      );
    }

    await _runGoogleAuthStep(_stepNativeSignOut, _googleSignIn.signOut);

    final googleUser = await _runGoogleAuthStep(
      _stepAccountPicker,
      _googleSignIn.signIn,
    );
    if (googleUser == null) {
      _logGoogleAuthStep(_stepAccountPicker, 'cancelled by user');
      throw const GoogleAuthServiceException(
        'cancelled',
        _cancelledMessage,
        null,
        _stepAccountPicker,
      );
    }

    await _runGoogleAuthStep(
      _stepPasswordAccountGuard,
      () => _guardAgainstPasswordOnlyAccount(googleUser.email),
    );

    final googleAuth = await _runGoogleAuthStep(
      _stepGoogleTokens,
      () => googleUser.authentication,
    );
    _logGoogleAuthStep(
      _stepGoogleTokens,
      'received accessToken=${_tokenPresence(googleAuth.accessToken)}; '
      'idToken=${_tokenPresence(googleAuth.idToken)}',
    );

    if (googleAuth.accessToken == null && googleAuth.idToken == null) {
      throw const GoogleAuthServiceException(
        'missing-google-token',
        'Google sign-in did not return authentication tokens. Please update the Firebase Android SHA fingerprints and google-services.json.',
        null,
        _stepGoogleTokens,
      );
    }

    final credential = _runGoogleAuthSyncStep(
      _stepFirebaseCredential,
      () => GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );

    return _runGoogleAuthStep(
      _stepFirebaseCredentialSignIn,
      () => _auth.signInWithCredential(credential),
    );
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
        final existingData = snapshot.data();
        final providerUpdate = userModel.toProviderUpdateMap();
        if (_hasSavedString(existingData, 'name')) {
          providerUpdate.remove('name');
        }
        if (_hasSavedString(existingData, 'photoUrl')) {
          providerUpdate.remove('photoUrl');
        }

        transaction.set(userRef, providerUpdate, SetOptions(merge: true));
      } else {
        createdUserRecord = true;
        transaction.set(userRef, userModel.toCreateMap());
      }
    });

    return createdUserRecord;
  }

  bool _hasSavedString(Map<String, dynamic>? data, String field) {
    final value = data?[field];
    return value is String && value.trim().isNotEmpty;
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
      case 'user-cancelled':
      case 'user_cancelled':
        return GoogleAuthServiceException(error.code, _cancelledMessage, error);
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
      case 'invalid-api-key':
      case 'app-not-authorized':
        return GoogleAuthServiceException(
          error.code,
          'Firebase Authentication is not configured correctly for this Android app.',
          error,
        );
      case 'invalid-credential':
      case 'malformed-credential':
        return GoogleAuthServiceException(
          error.code,
          _androidConfigMessage,
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
    if (_isPlatformCancellation(error)) {
      return GoogleAuthServiceException(error.code, _cancelledMessage, error);
    }

    if (_isPlatformNetworkError(error)) {
      return GoogleAuthServiceException(
        error.code,
        'No internet connection. Please check your network and try again.',
        error,
      );
    }

    if (_isAndroidDeveloperConfigError(error)) {
      return GoogleAuthServiceException(
        error.code,
        _androidConfigMessage,
        error,
      );
    }

    if (_isGooglePlayServicesError(error)) {
      return GoogleAuthServiceException(
        error.code,
        'Google Play Services is unavailable or out of date on this phone. Please update Google Play Services and try again.',
        error,
      );
    }

    switch (error.code) {
      case GoogleSignIn.kSignInFailedError:
        return GoogleAuthServiceException(
          error.code,
          'Unable to connect with Google right now. Please try again.',
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

  bool _isPlatformCancellation(PlatformException error) {
    return _googleAuthCancellationCodes.contains(error.code) ||
        error.code == GoogleSignIn.kSignInCanceledError ||
        _containsApiExceptionStatus(error, 12501);
  }

  bool _isPlatformNetworkError(PlatformException error) {
    return error.code == GoogleSignIn.kNetworkError ||
        _containsApiExceptionStatus(error, 7) ||
        _platformMessageContains(error, const ['NETWORK_ERROR']);
  }

  bool _isAndroidDeveloperConfigError(PlatformException error) {
    return _containsApiExceptionStatus(error, 10) ||
        _platformMessageContains(error, const ['DEVELOPER_ERROR']);
  }

  bool _isGooglePlayServicesError(PlatformException error) {
    return _containsApiExceptionStatus(error, 1) ||
        _containsApiExceptionStatus(error, 2) ||
        _containsApiExceptionStatus(error, 3) ||
        _containsApiExceptionStatus(error, 9) ||
        _platformMessageContains(error, const [
          'SERVICE_MISSING',
          'SERVICE_VERSION_UPDATE_REQUIRED',
          'SERVICE_DISABLED',
          'SERVICE_INVALID',
          'Google Play services',
        ]);
  }

  bool _containsApiExceptionStatus(PlatformException error, int statusCode) {
    return RegExp(
      'ApiException:\\s*$statusCode\\b',
      caseSensitive: false,
    ).hasMatch(_platformDiagnosticText(error));
  }

  bool _platformMessageContains(
    PlatformException error,
    Iterable<String> markers,
  ) {
    final message = _platformDiagnosticText(error).toLowerCase();
    return markers.any((marker) => message.contains(marker.toLowerCase()));
  }

  Future<T> _runGoogleAuthStep<T>(
    String step,
    Future<T> Function() action,
  ) async {
    _logGoogleAuthStep(step, 'start');
    try {
      final result = await action();
      _logGoogleAuthStep(step, 'success');
      return result;
    } catch (error, stackTrace) {
      _logGoogleAuthFailure(step, error, stackTrace);
      rethrow;
    }
  }

  T _runGoogleAuthSyncStep<T>(String step, T Function() action) {
    _logGoogleAuthStep(step, 'start');
    try {
      final result = action();
      _logGoogleAuthStep(step, 'success');
      return result;
    } catch (error, stackTrace) {
      _logGoogleAuthFailure(step, error, stackTrace);
      rethrow;
    }
  }

  void _logGoogleAuthStep(String step, String message) {
    debugPrint('[GoogleAuthService][$step] $message');
  }

  void _logGoogleAuthFailure(String step, Object error, StackTrace stackTrace) {
    final code = _diagnosticCode(error);
    final message = _diagnosticMessage(error);
    final details = _diagnosticDetails(error);
    final googleStatusCode = _googleApiStatusCode(error);
    debugPrint('[GoogleAuthService][$step] failed');
    debugPrint('[GoogleAuthService][$step] exceptionType=${error.runtimeType}');
    if (code != null && code.isNotEmpty) {
      debugPrint('[GoogleAuthService][$step] exceptionCode=$code');
    }
    if (googleStatusCode != null) {
      debugPrint(
        '[GoogleAuthService][$step] googleApiStatusCode=$googleStatusCode',
      );
    }
    if (message != null && message.isNotEmpty) {
      debugPrint(
        '[GoogleAuthService][$step] exceptionMessage=${_sanitizeDiagnosticMessage(message)}',
      );
    }
    if (details != null && details.isNotEmpty) {
      debugPrint(
        '[GoogleAuthService][$step] exceptionDetails=${_sanitizeDiagnosticMessage(details)}',
      );
    }
    _logGoogleAuthCause(step, error);
    debugPrint('[GoogleAuthService][$step] stackTrace=$stackTrace');
  }

  String? _diagnosticCode(Object error) {
    if (error is GoogleAuthServiceException) {
      return error.code;
    }
    if (error is FirebaseException) {
      return error.code;
    }
    if (error is PlatformException) {
      return error.code;
    }
    return null;
  }

  String? _diagnosticDetails(Object error) {
    final cause = error is GoogleAuthServiceException ? error.cause : error;
    if (cause is PlatformException && cause.details != null) {
      return cause.details.toString();
    }
    if (cause is FirebaseException) {
      return 'plugin=${cause.plugin}';
    }
    return null;
  }

  String? _diagnosticMessage(Object error) {
    if (error is GoogleAuthServiceException) {
      return error.message;
    }
    if (error is FirebaseException) {
      return error.message;
    }
    if (error is PlatformException) {
      return error.message;
    }
    return error.toString();
  }

  void _logGoogleAuthCause(String step, Object error) {
    if (error is! GoogleAuthServiceException || error.cause == null) {
      return;
    }

    final cause = error.cause!;
    final code = _diagnosticCode(cause);
    final message = _diagnosticMessage(cause);
    final details = _diagnosticDetails(cause);
    final googleStatusCode = _googleApiStatusCode(cause);

    debugPrint('[GoogleAuthService][$step] causeType=${cause.runtimeType}');
    if (code != null && code.isNotEmpty) {
      debugPrint('[GoogleAuthService][$step] causeCode=$code');
    }
    if (googleStatusCode != null) {
      debugPrint(
        '[GoogleAuthService][$step] causeGoogleApiStatusCode=$googleStatusCode',
      );
    }
    if (message != null && message.isNotEmpty) {
      debugPrint(
        '[GoogleAuthService][$step] causeMessage=${_sanitizeDiagnosticMessage(message)}',
      );
    }
    if (details != null && details.isNotEmpty) {
      debugPrint(
        '[GoogleAuthService][$step] causeDetails=${_sanitizeDiagnosticMessage(details)}',
      );
    }
  }

  int? _googleApiStatusCode(Object error) {
    final cause = error is GoogleAuthServiceException ? error.cause : error;
    if (cause is! PlatformException) {
      return null;
    }

    final match = RegExp(
      r'(?:ApiException:\s*|statusCode[=:]\s*|status code[=:]\s*)(-?\d+)\b',
      caseSensitive: false,
    ).firstMatch(_platformDiagnosticText(cause));

    return int.tryParse(match?.group(1) ?? '');
  }

  String _platformDiagnosticText(PlatformException error) {
    return [
      error.code,
      if (error.message != null) error.message!,
      if (error.details != null) error.details.toString(),
    ].join(' ');
  }

  String _sanitizeDiagnosticMessage(String message) {
    var sanitized = message.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '[REDACTED_JWT]',
    );

    sanitized = sanitized.replaceAll(
      RegExp(r'AIza[0-9A-Za-z_-]{35}'),
      '[REDACTED_API_KEY]',
    );

    sanitized = sanitized.replaceAll(
      RegExp(
        r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        caseSensitive: false,
      ),
      '[REDACTED_EMAIL]',
    );

    sanitized = sanitized.replaceAll(
      RegExp(r'\bBearer\s+[A-Za-z0-9._-]+', caseSensitive: false),
      'Bearer [REDACTED]',
    );

    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'\b(access[_-]?token|id[_-]?token|api[_-]?key|password|secret)=([^\s,;]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=[REDACTED]',
    );

    return sanitized;
  }

  String _tokenPresence(String? token) => token == null ? 'absent' : 'present';

  Future<void> _safeSignOut() async {
    await _auth.signOut();
    if (!kIsWeb && _supportsNativeGoogleSignIn) {
      await _googleSignIn.signOut();
    }
  }
}
