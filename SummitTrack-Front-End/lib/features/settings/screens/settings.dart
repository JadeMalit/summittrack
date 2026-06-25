import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Hiker';
    final userEmail = user?.email ?? 'No email connected';
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: _SettingsThemeTransition(
        child: _SettingsBody(
          userName: userName,
          userEmail: userEmail,
          photoUrl: user?.photoURL,
          onShowSnack: _showSnack,
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsThemeTransition extends StatelessWidget {
  const _SettingsThemeTransition({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final isDarkMode = themeController.isDarkMode;

        return AnimatedSwitcher(
          duration: AppTheme.animationDuration,
          reverseDuration: AppTheme.animationDuration,
          switchInCurve: AppTheme.animationCurve,
          switchOutCurve: AppTheme.animationCurve,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (transitionChild, animation) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: AppTheme.animationCurve,
              reverseCurve: AppTheme.animationCurve,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: transitionChild,
            );
          },
          child: RepaintBoundary(
            key: ValueKey<bool>(isDarkMode),
            child: Theme(
              data: isDarkMode ? AppTheme.dark : AppTheme.light,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    required this.onShowSnack,
  });

  final String userName;
  final String userEmail;
  final String? photoUrl;
  final void Function(BuildContext context, String message) onShowSnack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ColoredBox(
      color: colors.background,
      child: ListView(
        key: const PageStorageKey<String>('settings-list'),
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileSettingsHeader(
            userName: userName,
            userEmail: userEmail,
            photoUrl: photoUrl,
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            children: [
              const _DarkModeSettingsTile(),
              _SettingsTile(
                icon: Icons.account_circle_rounded,
                title: 'Account',
                subtitle: 'Profile and personal information',
                onTap: () => onShowSnack(
                  context,
                  'Account settings are ready for hookup.',
                ),
              ),
              _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Trail reminders and hike alerts',
                onTap: () => onShowSnack(
                  context,
                  'Notification settings are ready for hookup.',
                ),
              ),
              _SettingsTile(
                icon: Icons.security_rounded,
                title: 'Privacy and security',
                subtitle: 'Manage app access and safety options',
                onTap: () => onShowSnack(
                  context,
                  'Privacy settings are ready for hookup.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help',
                subtitle: 'Get support for SummitTrack',
                onTap: () =>
                    onShowSnack(context, 'Help center is ready for hookup.'),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'App details and version information',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'SummitTrack',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(
                      Icons.terrain_rounded,
                      color: colors.accent,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSettingsHeader extends StatelessWidget {
  const _ProfileSettingsHeader({
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
  });

  final String userName;
  final String userEmail;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.profileTop,
            colors.profileMiddle,
            isDark ? colors.surfaceHigh : colors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? colors.softHighlight.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: isDark ? 18 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isDark ? colors.surfaceMuted : Colors.white,
            backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
            child: photoUrl == null
                ? Icon(
                    Icons.person_rounded,
                    color: isDark ? colors.softHighlight : colors.primary,
                    size: 34,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: isDark ? 0.82 : 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkModeSettingsTile extends StatelessWidget {
  const _DarkModeSettingsTile();

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: themeController.isChangingThemeListenable,
      builder: (context, isChangingTheme, _) {
        final colors = context.appColors;
        final isDarkMode = context.isDarkMode;

        return _SettingsTileShell(
          onTap: isChangingTheme
              ? null
              : () {
                  themeController.toggleDarkMode();
                },
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: AppTheme.animationCurve,
            switchOutCurve: AppTheme.animationCurve,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
              key: ValueKey(isDarkMode),
              color: colors.accent,
            ),
          ),
          title: 'Dark Mode',
          subtitle: isDarkMode ? 'Moonlit trail view' : 'Bright trail view',
          trailing: _DarkModeToggleButton(
            isDarkMode: isDarkMode,
            isChangingTheme: isChangingTheme,
          ),
        );
      },
    );
  }
}

class _DarkModeToggleButton extends StatelessWidget {
  const _DarkModeToggleButton({
    required this.isDarkMode,
    required this.isChangingTheme,
  });

  final bool isDarkMode;
  final bool isChangingTheme;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      toggled: isDarkMode,
      enabled: !isChangingTheme,
      label: 'Dark Mode',
      child: AnimatedContainer(
        duration: AppTheme.animationDuration,
        curve: AppTheme.animationCurve,
        width: 64,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDarkMode
              ? colors.accent.withValues(alpha: 0.22)
              : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDarkMode
                ? colors.accent.withValues(alpha: 0.62)
                : colors.border,
          ),
        ),
        child: AnimatedAlign(
          duration: AppTheme.animationDuration,
          curve: AppTheme.animationCurve,
          alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDarkMode ? colors.softHighlight : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
              color: isDarkMode ? colors.background : colors.warning,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 72,
                endIndent: 18,
                color: colors.divider,
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsTileShell(
      onTap: onTap,
      leading: Icon(icon, color: context.appColors.accent),
      title: title,
      subtitle: subtitle,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.appColors.textSecondary,
      ),
    );
  }
}

class _SettingsTileShell extends StatelessWidget {
  const _SettingsTileShell({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final VoidCallback? onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.iconBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: leading),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
      ),
      trailing: trailing,
    );
  }
}
