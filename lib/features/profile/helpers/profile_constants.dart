import 'package:flutter/material.dart';

class ProfileConstants {
  ProfileConstants._();

  static const Color pageBackground = Color(0xFFF3F6F0);
  static const Color cardTop = Color(0xFF2E6C42);
  static const Color cardMiddle = Color(0xFF4D8350);
  static const Color cardBottom = Color(0xFFB7D29A);
  static const Color logoutTop = Color(0xFF33573A);
  static const Color logoutBottom = Color(0xFF203628);
  static const Color textDark = Color(0xFF1B241C);
  static const Color surfaceBorder = Color(0xFFDCE4D7);
  static const Color softCard = Color(0xFFF8FAF6);

  static const String nameKey = 'profile_full_name';
  static const String emailKey = 'profile_email';
  static const String phoneKey = 'profile_phone';
  static const String addressKey = 'profile_address';
  static const String bioKey = 'profile_bio';
  static const String avatarKey = 'profile_avatar_base64';

  static const Duration introDuration = Duration(milliseconds: 700);
  static const Duration detailPressDuration = Duration(milliseconds: 120);

  static const double headerHorizontalPadding = 16;
  static const double headerTopPadding = 10;
  static const double topBarHeight = 56;
  static const double cardTopOffset = 78;
  static const double avatarOverlap = 54;
  static const double detailItemHeight = 44;
  static const double detailItemStart = 0.22;
  static const double detailItemStep = 0.08;
  static const double detailItemDuration = 0.32;
}
