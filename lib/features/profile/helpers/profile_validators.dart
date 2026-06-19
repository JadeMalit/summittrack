import 'profile_models.dart';

extension ProfileEditableFieldValidators on ProfileEditableField {
  String? validate(String? value) {
    final trimmedValue = value?.trim() ?? '';

    switch (this) {
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
      case ProfileEditableField.fullName:
      case ProfileEditableField.address:
      case ProfileEditableField.bio:
        return null;
    }
  }
}
