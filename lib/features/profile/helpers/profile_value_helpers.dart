import 'package:firebase_auth/firebase_auth.dart';

import 'profile_models.dart';

String resolvePrimaryName(User? user) {
  final displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final email = user?.email?.trim();
  if (email != null && email.isNotEmpty && email.contains('@')) {
    return email.split('@').first;
  }

  return 'Guest';
}

String sanitizeValue(String? value) {
  return value?.trim() ?? '';
}

String profileValueForField({
  required ProfileEditableField field,
  required String fullName,
  required String email,
  required String phone,
  required String address,
  required String bio,
}) {
  switch (field) {
    case ProfileEditableField.fullName:
      return fullName;
    case ProfileEditableField.email:
      return email;
    case ProfileEditableField.phone:
      return phone;
    case ProfileEditableField.address:
      return address;
    case ProfileEditableField.bio:
      return bio;
  }
}

String profileDisplayValueForField({
  required ProfileEditableField field,
  required String fullName,
  required String email,
  required String phone,
  required String address,
  required String bio,
  required User? currentUser,
}) {
  final value = profileValueForField(
    field: field,
    fullName: fullName,
    email: email,
    phone: phone,
    address: address,
    bio: bio,
  ).trim();

  if (value.isNotEmpty) {
    return value;
  }

  switch (field) {
    case ProfileEditableField.fullName:
      return resolvePrimaryName(currentUser);
    case ProfileEditableField.email:
      return 'No email added';
    case ProfileEditableField.phone:
      return 'No phone number added';
    case ProfileEditableField.address:
      return 'No address added';
    case ProfileEditableField.bio:
      return 'No bio added';
  }
}
