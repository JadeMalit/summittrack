import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'profile_models.dart';

final RegExp _fullNameValidationPattern = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');

String normalizeProfileFullName(
  String value, {
  bool preserveTrailingSpace = false,
}) {
  var normalized = value.replaceAll(RegExp(r'[^A-Za-z ]'), '');
  normalized = normalized.replaceFirst(RegExp(r'^\s+'), '');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

  if (!preserveTrailingSpace) {
    normalized = normalized.trimRight();
  }

  return normalized;
}

String normalizeProfileFieldValue(ProfileEditableField field, String value) {
  switch (field) {
    case ProfileEditableField.fullName:
      return normalizeProfileFullName(value).trim();
    case ProfileEditableField.email:
    case ProfileEditableField.phone:
    case ProfileEditableField.address:
    case ProfileEditableField.bio:
      return value.trim();
  }
}

List<TextInputFormatter>? profileInputFormattersForField(
  ProfileEditableField field,
) {
  switch (field) {
    case ProfileEditableField.fullName:
      return const [ProfileFullNameInputFormatter()];
    case ProfileEditableField.email:
    case ProfileEditableField.phone:
    case ProfileEditableField.address:
    case ProfileEditableField.bio:
      return field.inputFormatters;
  }
}

class ProfileFullNameInputFormatter extends TextInputFormatter {
  const ProfileFullNameInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeProfileFullName(
      newValue.text,
      preserveTrailingSpace: true,
    );

    if (normalized == newValue.text) {
      return newValue;
    }

    final selectionIndex = math.min(normalized.length, newValue.selection.end);

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: selectionIndex),
      composing: TextRange.empty,
    );
  }
}

extension ProfileEditableFieldValidators on ProfileEditableField {
  String? validate(String? value) {
    final trimmedValue = normalizeProfileFieldValue(this, value ?? '');

    switch (this) {
      case ProfileEditableField.fullName:
        if (trimmedValue.isEmpty) {
          return 'Full name is required.';
        }
        if (!_fullNameValidationPattern.hasMatch(trimmedValue)) {
          return 'Full name must contain letters only.';
        }
        return null;
      case ProfileEditableField.email:
        if (trimmedValue.isEmpty) {
          return null;
        }
        const emailPattern =
            r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
        if (!RegExp(emailPattern).hasMatch(trimmedValue)) {
          return 'Enter a valid email address';
        }
        return null;
      case ProfileEditableField.phone:
        if (trimmedValue.isEmpty) {
          return null;
        }
        if (!RegExp(r'^\d+$').hasMatch(trimmedValue)) {
          return 'Use numbers only';
        }
        return null;
      case ProfileEditableField.address:
      case ProfileEditableField.bio:
        return null;
    }
  }
}
