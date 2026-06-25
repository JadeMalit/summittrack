import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const animationDuration = Duration(milliseconds: 320);
  static const animationCurve = Curves.easeInOut;

  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    colors: AppColors.light,
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    colors: AppColors.dark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.accent,
      onSecondary: isDark ? const Color(0xFF07110A) : Colors.white,
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: isDark ? const Color(0xFF690005) : Colors.white,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceHigh,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.divider,
    );

    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.divider,
      shadowColor: colors.shadow,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colors.textSecondary),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.shadow,
        elevation: isDark ? 0 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.accent,
        textColor: colors.textPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.navBackground,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? colors.softHighlight : Colors.white;
          }
          return isDark ? colors.textSecondary : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? colors.accent.withValues(alpha: 0.42)
                : colors.primary.withValues(alpha: 0.42);
          }
          return isDark ? colors.surfaceMuted : const Color(0xFFD7E3D1);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent.withValues(alpha: 0.70);
          }
          return colors.border;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.textSecondary),
        labelStyle: TextStyle(color: colors.textSecondary),
        prefixIconColor: colors.accent,
        suffixIconColor: colors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accent, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? colors.surfaceHigh : const Color(0xFF172219),
        contentTextStyle: TextStyle(
          color: isDark ? colors.textPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.surfaceMuted,
          disabledForegroundColor: colors.textSecondary,
          elevation: isDark ? 0 : 1,
          shadowColor: colors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.accent),
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
