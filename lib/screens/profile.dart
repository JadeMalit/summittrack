import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const Color _topSectionBackground = Color(0xFFE5E5E5);
  static const Color _cardTop = Color(0xFF2F7A1F);
  static const Color _cardMiddle = Color(0xFF77B93D);
  static const Color _cardBottom = Color(0xFFD6EC68);
  static const Color _logoutTop = Color(0xFF1A46C7);
  static const Color _logoutBottom = Color(0xFF081A7D);
  static const Color _textDark = Color(0xFF1E1E1E);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _nameKey = 'profile_full_name';
  static const String _emailKey = 'profile_email';
  static const String _phoneKey = 'profile_phone';
  static const String _addressKey = 'profile_address';
  static const String _bioKey = 'profile_bio';
  static const String _avatarKey = 'profile_avatar_base64';

  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _bio = '';
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _seedProfileFromAuth();
    _loadStoredProfile();
  }

  void _seedProfileFromAuth() {
    final user = FirebaseAuth.instance.currentUser;
    _fullName = _resolvePrimaryName(user);
    _email = _sanitizeValue(user?.email);
    _phone = _sanitizeValue(user?.phoneNumber);
  }

  Future<void> _loadStoredProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAvatar = prefs.getString(_avatarKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _fullName = prefs.getString(_nameKey)?.trim() ?? _fullName;
      _email = prefs.getString(_emailKey)?.trim() ?? _email;
      _phone = prefs.getString(_phoneKey)?.trim() ?? _phone;
      _address = prefs.getString(_addressKey)?.trim() ?? _address;
      _bio = prefs.getString(_bioKey)?.trim() ?? _bio;
      _avatarBytes = _decodeAvatar(storedAvatar);
    });
  }

  Future<void> _saveField(_EditableField field, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(field.storageKey, value);
  }

  Future<void> _showEditSheet(_EditableField field) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditProfileSheet(
          field: field,
          initialValue: _valueForField(field),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      switch (field) {
        case _EditableField.fullName:
          _fullName = result;
          break;
        case _EditableField.email:
          _email = result;
          break;
        case _EditableField.phone:
          _phone = result;
          break;
        case _EditableField.address:
          _address = result;
          break;
        case _EditableField.bio:
          _bio = result;
          break;
      }
    });

    await _saveField(field, result);
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty || !mounted) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarKey, base64Encode(bytes));

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load that image right now.')),
      );
    }
  }

  String _valueForField(_EditableField field) {
    switch (field) {
      case _EditableField.fullName:
        return _fullName;
      case _EditableField.email:
        return _email;
      case _EditableField.phone:
        return _phone;
      case _EditableField.address:
        return _address;
      case _EditableField.bio:
        return _bio;
    }
  }

  String _displayValueForField(_EditableField field) {
    final value = _valueForField(field).trim();
    if (value.isNotEmpty) {
      return value;
    }

    switch (field) {
      case _EditableField.fullName:
        return _resolvePrimaryName(FirebaseAuth.instance.currentUser);
      case _EditableField.email:
        return 'No email added';
      case _EditableField.phone:
        return 'No phone number added';
      case _EditableField.address:
        return 'No address added';
      case _EditableField.bio:
        return 'No bio added';
    }
  }

  String get _primaryName {
    final currentName = _fullName.trim();
    if (currentName.isNotEmpty) {
      return currentName;
    }

    final currentEmail = _email.trim();
    if (currentEmail.isNotEmpty && currentEmail.contains('@')) {
      return currentEmail.split('@').first;
    }

    return 'Guest';
  }

  Uint8List? _decodeAvatar(String? encodedAvatar) {
    if (encodedAvatar == null || encodedAvatar.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encodedAvatar);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: ProfileScreen._topSectionBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 14.0;
            const topBarHeight = 58.0;
            const cardTop = 74.0;
            const avatarOverlap = 52.0;

            return Stack(
              children: [
                Positioned.fill(
                  child: Container(color: ProfileScreen._topSectionBackground),
                ),
                Positioned(
                  top: 12,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  child: SizedBox(
                    height: topBarHeight,
                    child: Row(
                      children: [
                        _TopIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        const _TopIconBadge(icon: Icons.home_rounded),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: cardTop,
                  bottom: 0,
                  child: _ProfileCard(
                    primaryName: _primaryName,
                    details: [
                      _ProfileDetail(
                        field: _EditableField.fullName,
                        label: 'Full Name / Username',
                        value: _displayValueForField(_EditableField.fullName),
                      ),
                      _ProfileDetail(
                        field: _EditableField.email,
                        label: 'Email',
                        value: _displayValueForField(_EditableField.email),
                      ),
                      _ProfileDetail(
                        field: _EditableField.phone,
                        label: 'Phone Number',
                        value: _displayValueForField(_EditableField.phone),
                      ),
                      _ProfileDetail(
                        field: _EditableField.address,
                        label: 'Address',
                        value: _displayValueForField(_EditableField.address),
                      ),
                      _ProfileDetail(
                        field: _EditableField.bio,
                        label: 'Bio',
                        value: _displayValueForField(_EditableField.bio),
                      ),
                    ],
                    onDetailTap: _showEditSheet,
                    onLogout: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
                Positioned(
                  top: cardTop - avatarOverlap,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _ProfileAvatar(
                      photoUrl: user?.photoURL,
                      avatarBytes: _avatarBytes,
                      onAddPhoto: _pickProfileImage,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _resolvePrimaryName(User? user) {
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

  static String _sanitizeValue(String? value) {
    return value?.trim() ?? '';
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.primaryName,
    required this.details,
    required this.onDetailTap,
    required this.onLogout,
  });

  final String primaryName;
  final List<_ProfileDetail> details;
  final ValueChanged<_EditableField> onDetailTap;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ProfileScreen._cardTop,
            ProfileScreen._cardMiddle,
            ProfileScreen._cardBottom,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 74, 18, 24 + bottomInset),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          primaryName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 90,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 22),
                        for (final detail in details) ...[
                          _DetailField(
                            detail: detail,
                            onTap: () => onDetailTap(detail.field),
                          ),
                          if (detail != details.last)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: SizedBox(
                        width: 170,
                        child: _LogoutButton(onPressed: onLogout),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.avatarBytes,
    required this.onAddPhoto,
  });

  final String? photoUrl;
  final Uint8List? avatarBytes;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final hasLocalPhoto = avatarBytes != null && avatarBytes!.isNotEmpty;
    final hasNetworkPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    ImageProvider<Object>? imageProvider;
    if (hasLocalPhoto) {
      imageProvider = MemoryImage(avatarBytes!);
    } else if (hasNetworkPhoto) {
      imageProvider = NetworkImage(photoUrl!);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD6D6D6),
            border: Border.all(color: const Color(0xFF8D8D8D), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
              child: imageProvider != null
                  ? Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      size: 48,
                      color: ProfileScreen._textDark,
                    ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddPhoto,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF8D8D8D), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: ProfileScreen._cardTop,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.detail, required this.onTap});

  final _ProfileDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.label,
                      style: const TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail.value,
                      style: const TextStyle(
                        color: ProfileScreen._textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: ProfileScreen._textDark.withValues(alpha: 0.70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.field, required this.initialValue});

  final _EditableField field;
  final String initialValue;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Edit ${widget.field.label}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ProfileScreen._textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: widget.field.keyboardType,
                    textInputAction: TextInputAction.done,
                    maxLines: widget.field.maxLines,
                    minLines: widget.field.maxLines > 1 ? 3 : 1,
                    inputFormatters: widget.field.inputFormatters,
                    validator: widget.field.validate,
                    onFieldSubmitted: (_) {
                      if (widget.field.maxLines == 1) {
                        _submit();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: widget.field.hintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCECECE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: ProfileScreen._cardTop,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFBEBEBE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProfileScreen._cardTop,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ProfileScreen._logoutTop, ProfileScreen._logoutBottom],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF081A7D).withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          await onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
      ),
    );
  }
}

class _TopIconBadge extends StatelessWidget {
  const _TopIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Icon(icon, color: Colors.black87, size: 20),
    );
  }
}

class _ProfileDetail {
  const _ProfileDetail({
    required this.field,
    required this.label,
    required this.value,
  });

  final _EditableField field;
  final String label;
  final String value;
}

enum _EditableField { fullName, email, phone, address, bio }

extension on _EditableField {
  String get label {
    switch (this) {
      case _EditableField.fullName:
        return 'Full Name / Username';
      case _EditableField.email:
        return 'Email';
      case _EditableField.phone:
        return 'Phone Number';
      case _EditableField.address:
        return 'Address';
      case _EditableField.bio:
        return 'Bio';
    }
  }

  String get storageKey {
    switch (this) {
      case _EditableField.fullName:
        return _ProfileScreenState._nameKey;
      case _EditableField.email:
        return _ProfileScreenState._emailKey;
      case _EditableField.phone:
        return _ProfileScreenState._phoneKey;
      case _EditableField.address:
        return _ProfileScreenState._addressKey;
      case _EditableField.bio:
        return _ProfileScreenState._bioKey;
    }
  }

  String get hintText {
    switch (this) {
      case _EditableField.fullName:
        return 'Enter your full name or username';
      case _EditableField.email:
        return 'Enter your email';
      case _EditableField.phone:
        return 'Enter your phone number';
      case _EditableField.address:
        return 'Enter your address';
      case _EditableField.bio:
        return 'Tell us about yourself';
    }
  }

  TextInputType get keyboardType {
    switch (this) {
      case _EditableField.email:
        return TextInputType.emailAddress;
      case _EditableField.phone:
        return TextInputType.phone;
      case _EditableField.address:
        return TextInputType.streetAddress;
      case _EditableField.bio:
      case _EditableField.fullName:
        return TextInputType.text;
    }
  }

  int get maxLines {
    switch (this) {
      case _EditableField.address:
        return 3;
      case _EditableField.bio:
        return 4;
      case _EditableField.fullName:
      case _EditableField.email:
      case _EditableField.phone:
        return 1;
    }
  }

  List<TextInputFormatter>? get inputFormatters {
    switch (this) {
      case _EditableField.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      case _EditableField.fullName:
      case _EditableField.email:
      case _EditableField.address:
      case _EditableField.bio:
        return null;
    }
  }

  String? validate(String? value) {
    final trimmedValue = value?.trim() ?? '';

    switch (this) {
      case _EditableField.email:
        if (trimmedValue.isEmpty) {
          return null;
        }
        const emailPattern =
            r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
        if (!RegExp(emailPattern).hasMatch(trimmedValue)) {
          return 'Enter a valid email address';
        }
        return null;
      case _EditableField.phone:
        if (trimmedValue.isEmpty) {
          return null;
        }
        if (!RegExp(r'^\d+$').hasMatch(trimmedValue)) {
          return 'Use numbers only';
        }
        return null;
      case _EditableField.fullName:
      case _EditableField.address:
      case _EditableField.bio:
        return null;
    }
  }
}
