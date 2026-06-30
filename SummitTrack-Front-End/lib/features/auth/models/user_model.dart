import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.authProvider,
    required this.providers,
    required this.emailVerified,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String authProvider;
  final List<String> providers;
  final bool emailVerified;
  final String? photoUrl;

  factory UserModel.fromFirebaseUser(
    User user, {
    required String authProvider,
  }) {
    final providerLabels =
        user.providerData
            .map((provider) => _providerLabel(provider.providerId))
            .where((provider) => provider.isNotEmpty)
            .toSet()
          ..add(authProvider);

    return UserModel(
      uid: user.uid,
      name: _resolveName(user),
      email: user.email?.trim().toLowerCase() ?? '',
      authProvider: authProvider,
      providers: providerLabels.toList()..sort(),
      emailVerified: user.emailVerified,
      photoUrl: user.photoURL?.trim(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
      'authProvider': authProvider,
      'providers': providers,
      'emailVerified': emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toProviderUpdateMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
      'authProvider': authProvider,
      'providers': FieldValue.arrayUnion(providers),
      'emailVerified': emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }

  static String _resolveName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Google User';
  }

  static String _providerLabel(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'google';
      case 'password':
        return 'password';
      default:
        return providerId;
    }
  }
}
