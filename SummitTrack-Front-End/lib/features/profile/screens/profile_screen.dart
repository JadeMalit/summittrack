import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../helpers/profile_constants.dart';
import '../helpers/profile_models.dart';
import '../helpers/profile_validators.dart';
import '../helpers/profile_value_helpers.dart';
import '../widgets/profile_avatar_section.dart';
import '../widgets/profile_background.dart';
import '../widgets/profile_edit_fields.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/logout_confirmation_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String _fullName = '';
  String _phone = '';
  String _address = '';
  String _bio = '';
  Uint8List? _avatarBytes;

  late final AnimationController _introController;
  late final Animation<double> _fadeInAnimation;
  late final Animation<Offset> _slideAnimation;

  String get _authenticatedEmail =>
      sanitizeValue(FirebaseAuth.instance.currentUser?.email);

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: ProfileConstants.introDuration,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    _seedProfileFromAuth();
    _loadStoredProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _introController.forward();
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  void _seedProfileFromAuth() {
    final user = FirebaseAuth.instance.currentUser;
    _fullName = resolvePrimaryName(user);
    _phone = sanitizeValue(user?.phoneNumber);
  }

  Future<void> _loadStoredProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAvatar = prefs.getString(ProfileConstants.avatarKey);
    await prefs.remove(ProfileConstants.emailKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _fullName =
          prefs.getString(ProfileConstants.nameKey)?.trim() ?? _fullName;
      _phone = prefs.getString(ProfileConstants.phoneKey)?.trim() ?? _phone;
      _address =
          prefs.getString(ProfileConstants.addressKey)?.trim() ?? _address;
      _bio = prefs.getString(ProfileConstants.bioKey)?.trim() ?? _bio;
      _avatarBytes = _decodeAvatar(storedAvatar);
    });
  }

  Future<void> _saveField(ProfileEditableField field, String value) async {
    if (!field.isEditable) {
      return;
    }

    final normalizedValue = normalizeProfileFieldValue(field, value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(field.storageKey, normalizedValue);

    if (field == ProfileEditableField.fullName) {
      await _syncFullName(normalizedValue);
    }
  }

  Future<void> _syncFullName(String fullName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || fullName.isEmpty) {
      return;
    }

    try {
      await user.updateDisplayName(fullName);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.reload();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Full name was updated locally, but we could not sync it right now.',
          ),
        ),
      );
    }
  }

  Future<void> _showEditSheet(ProfileEditableField field) async {
    if (!field.isEditable) {
      return;
    }

    final result = await showProfileEditSheet(
      context,
      field: field,
      initialValue: profileValueForField(
        field: field,
        fullName: _fullName,
        email: _authenticatedEmail,
        phone: _phone,
        address: _address,
        bio: _bio,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      switch (field) {
        case ProfileEditableField.fullName:
          _fullName = result;
          break;
        case ProfileEditableField.email:
          break;
        case ProfileEditableField.phone:
          _phone = result;
          break;
        case ProfileEditableField.address:
          _address = result;
          break;
        case ProfileEditableField.bio:
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
      await prefs.setString(ProfileConstants.avatarKey, base64Encode(bytes));

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

  String _displayValueForField(ProfileEditableField field) {
    return profileDisplayValueForField(
      field: field,
      fullName: _fullName,
      email: _authenticatedEmail,
      phone: _phone,
      address: _address,
      bio: _bio,
      currentUser: FirebaseAuth.instance.currentUser,
    );
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showLogoutConfirmationDialog(context);
    if (!mounted || !shouldLogout) {
      return;
    }

    final navigator = Navigator.of(context);

    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                const Positioned.fill(child: ProfileBackground()),
                Positioned(
                  top: ProfileConstants.headerTopPadding,
                  left: ProfileConstants.headerHorizontalPadding,
                  right: ProfileConstants.headerHorizontalPadding,
                  child: ProfileHeader(
                    onBackTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  left: ProfileConstants.headerHorizontalPadding,
                  right: ProfileConstants.headerHorizontalPadding,
                  top: ProfileConstants.cardTopOffset,
                  bottom: 0,
                  child: ProfileInfoCard(
                    primaryName: profileDisplayValueForField(
                      field: ProfileEditableField.fullName,
                      fullName: _fullName,
                      email: _authenticatedEmail,
                      phone: _phone,
                      address: _address,
                      bio: _bio,
                      currentUser: FirebaseAuth.instance.currentUser,
                    ),
                    details: [
                      ProfileDetail(
                        field: ProfileEditableField.fullName,
                        label: 'Full Name / Username',
                        value: _displayValueForField(
                          ProfileEditableField.fullName,
                        ),
                      ),
                      ProfileDetail(
                        field: ProfileEditableField.email,
                        label: 'Email',
                        value: _displayValueForField(
                          ProfileEditableField.email,
                        ),
                      ),
                      ProfileDetail(
                        field: ProfileEditableField.phone,
                        label: 'Phone Number',
                        value: _displayValueForField(
                          ProfileEditableField.phone,
                        ),
                      ),
                      ProfileDetail(
                        field: ProfileEditableField.address,
                        label: 'Address',
                        value: _displayValueForField(
                          ProfileEditableField.address,
                        ),
                      ),
                      ProfileDetail(
                        field: ProfileEditableField.bio,
                        label: 'Bio',
                        value: _displayValueForField(ProfileEditableField.bio),
                      ),
                    ],
                    onDetailTap: _showEditSheet,
                    onLogout: _handleLogout,
                    entryAnimation: _introController,
                  ),
                ),
                Positioned(
                  top:
                      ProfileConstants.cardTopOffset -
                      ProfileConstants.avatarOverlap,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ProfileAvatarSection(
                      photoUrl: user?.photoURL,
                      avatarBytes: _avatarBytes,
                      onAddPhoto: _pickProfileImage,
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
