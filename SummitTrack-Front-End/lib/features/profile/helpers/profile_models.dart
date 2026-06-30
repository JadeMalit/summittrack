import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'profile_constants.dart';

enum ProfileEditableField { fullName, email, phone, address, bio }

class ProfileDetail {
  const ProfileDetail({
    required this.field,
    required this.label,
    required this.value,
  });

  final ProfileEditableField field;
  final String label;
  final String value;
}

extension ProfileEditableFieldMetadata on ProfileEditableField {
  bool get isEditable {
    switch (this) {
      case ProfileEditableField.email:
        return false;
      case ProfileEditableField.fullName:
      case ProfileEditableField.phone:
      case ProfileEditableField.address:
      case ProfileEditableField.bio:
        return true;
    }
  }

  String get label {
    switch (this) {
      case ProfileEditableField.fullName:
        return 'Full Name / Username';
      case ProfileEditableField.email:
        return 'Email';
      case ProfileEditableField.phone:
        return 'Phone Number';
      case ProfileEditableField.address:
        return 'Address';
      case ProfileEditableField.bio:
        return 'Bio';
    }
  }

  String? get supportingText {
    switch (this) {
      case ProfileEditableField.email:
        return 'Email used for sign in';
      case ProfileEditableField.fullName:
      case ProfileEditableField.phone:
      case ProfileEditableField.address:
      case ProfileEditableField.bio:
        return null;
    }
  }

  IconData get trailingIcon {
    switch (this) {
      case ProfileEditableField.email:
        return Icons.lock_outline_rounded;
      case ProfileEditableField.fullName:
      case ProfileEditableField.phone:
      case ProfileEditableField.address:
      case ProfileEditableField.bio:
        return Icons.edit_outlined;
    }
  }

  String get storageKey {
    switch (this) {
      case ProfileEditableField.fullName:
        return ProfileConstants.nameKey;
      case ProfileEditableField.email:
        return ProfileConstants.emailKey;
      case ProfileEditableField.phone:
        return ProfileConstants.phoneKey;
      case ProfileEditableField.address:
        return ProfileConstants.addressKey;
      case ProfileEditableField.bio:
        return ProfileConstants.bioKey;
    }
  }

  String get hintText {
    switch (this) {
      case ProfileEditableField.fullName:
        return 'Enter your full name or username';
      case ProfileEditableField.email:
        return 'Enter your email';
      case ProfileEditableField.phone:
        return 'Enter your phone number';
      case ProfileEditableField.address:
        return 'Enter your address';
      case ProfileEditableField.bio:
        return 'Tell us about yourself';
    }
  }

  TextInputType get keyboardType {
    switch (this) {
      case ProfileEditableField.email:
        return TextInputType.emailAddress;
      case ProfileEditableField.phone:
        return TextInputType.phone;
      case ProfileEditableField.address:
        return TextInputType.streetAddress;
      case ProfileEditableField.bio:
      case ProfileEditableField.fullName:
        return TextInputType.text;
    }
  }

  int get maxLines {
    switch (this) {
      case ProfileEditableField.address:
        return 3;
      case ProfileEditableField.bio:
        return 4;
      case ProfileEditableField.fullName:
      case ProfileEditableField.email:
      case ProfileEditableField.phone:
        return 1;
    }
  }

  List<TextInputFormatter>? get inputFormatters {
    switch (this) {
      case ProfileEditableField.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      case ProfileEditableField.fullName:
      case ProfileEditableField.email:
      case ProfileEditableField.address:
      case ProfileEditableField.bio:
        return null;
    }
  }
}
