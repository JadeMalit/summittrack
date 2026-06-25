import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceMuted,
    required this.primary,
    required this.primaryPressed,
    required this.accent,
    required this.softHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.border,
    required this.iconBackground,
    required this.navBackground,
    required this.shadow,
    required this.profileTop,
    required this.profileMiddle,
    required this.profileBottom,
    required this.warning,
    required this.danger,
  });

  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceMuted;
  final Color primary;
  final Color primaryPressed;
  final Color accent;
  final Color softHighlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color border;
  final Color iconBackground;
  final Color navBackground;
  final Color shadow;
  final Color profileTop;
  final Color profileMiddle;
  final Color profileBottom;
  final Color warning;
  final Color danger;

  static const light = AppColors(
    background: Color(0xFFF4F7F1),
    backgroundAlt: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF8FAF6),
    surfaceMuted: Color(0xFFEAF6E8),
    primary: Color(0xFF0B5D1E),
    primaryPressed: Color(0xFF084816),
    accent: Color(0xFF3FA65B),
    softHighlight: Color(0xFF9BD86A),
    textPrimary: Color(0xFF182319),
    textSecondary: Color(0xFF62705F),
    divider: Color(0xFFDDE7D7),
    border: Color(0xFFDCE5D6),
    iconBackground: Color(0xFFEAF6E8),
    navBackground: Color(0xFFFFFFFF),
    shadow: Color(0x1A0B5D1E),
    profileTop: Color(0xFF2E6C42),
    profileMiddle: Color(0xFF4D8350),
    profileBottom: Color(0xFFB7D29A),
    warning: Color(0xFFB98914),
    danger: Color(0xFFE34A3B),
  );

  static const dark = AppColors(
    background: Color(0xFF0F1A14),
    backgroundAlt: Color(0xFF111F17),
    surface: Color(0xFF17251C),
    surfaceHigh: Color(0xFF1E3024),
    surfaceMuted: Color(0xFF213627),
    primary: Color(0xFF2E7D32),
    primaryPressed: Color(0xFF256428),
    accent: Color(0xFF4CAF50),
    softHighlight: Color(0xFF8EDB8F),
    textPrimary: Color(0xFFF1F5F2),
    textSecondary: Color(0xFFA8B5AA),
    divider: Color(0xFF26382D),
    border: Color(0xFF2B4032),
    iconBackground: Color(0xFF213627),
    navBackground: Color(0xFF17251C),
    shadow: Color(0x66000000),
    profileTop: Color(0xFF2E7D32),
    profileMiddle: Color(0xFF1F5E2B),
    profileBottom: Color(0xFF17251C),
    warning: Color(0xFFC3922E),
    danger: Color(0xFFE45B50),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceMuted,
    Color? primary,
    Color? primaryPressed,
    Color? accent,
    Color? softHighlight,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? border,
    Color? iconBackground,
    Color? navBackground,
    Color? shadow,
    Color? profileTop,
    Color? profileMiddle,
    Color? profileBottom,
    Color? warning,
    Color? danger,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      accent: accent ?? this.accent,
      softHighlight: softHighlight ?? this.softHighlight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      iconBackground: iconBackground ?? this.iconBackground,
      navBackground: navBackground ?? this.navBackground,
      shadow: shadow ?? this.shadow,
      profileTop: profileTop ?? this.profileTop,
      profileMiddle: profileMiddle ?? this.profileMiddle,
      profileBottom: profileBottom ?? this.profileBottom,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppColors(
      background: blend(background, other.background),
      backgroundAlt: blend(backgroundAlt, other.backgroundAlt),
      surface: blend(surface, other.surface),
      surfaceHigh: blend(surfaceHigh, other.surfaceHigh),
      surfaceMuted: blend(surfaceMuted, other.surfaceMuted),
      primary: blend(primary, other.primary),
      primaryPressed: blend(primaryPressed, other.primaryPressed),
      accent: blend(accent, other.accent),
      softHighlight: blend(softHighlight, other.softHighlight),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      divider: blend(divider, other.divider),
      border: blend(border, other.border),
      iconBackground: blend(iconBackground, other.iconBackground),
      navBackground: blend(navBackground, other.navBackground),
      shadow: blend(shadow, other.shadow),
      profileTop: blend(profileTop, other.profileTop),
      profileMiddle: blend(profileMiddle, other.profileMiddle),
      profileBottom: blend(profileBottom, other.profileBottom),
      warning: blend(warning, other.warning),
      danger: blend(danger, other.danger),
    );
  }
}

extension AppThemeColors on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
