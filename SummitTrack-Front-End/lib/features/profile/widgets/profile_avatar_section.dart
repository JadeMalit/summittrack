import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../helpers/profile_constants.dart';

class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
    required this.photoUrl,
    required this.avatarBytes,
    required this.onAddPhoto,
  });

  final String? photoUrl;
  final Uint8List? avatarBytes;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.isDarkMode
                ? colors.surfaceHigh
                : const Color(0xFFF6F8F3),
            border: Border.all(
              color: context.isDarkMode
                  ? colors.accent.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.78),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(color: colors.surfaceMuted),
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Icon(
                        Icons.person_outline_rounded,
                        size: 50,
                        color: colors.textPrimary,
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddPhoto,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? colors.accent : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.isDarkMode
                        ? colors.border
                        : ProfileConstants.surfaceBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: context.isDarkMode
                      ? colors.background
                      : colors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
