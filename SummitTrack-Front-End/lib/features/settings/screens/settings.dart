import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/layout/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../notifications/services/hike_notification_service.dart';

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Settings'),
      ),
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

class _SettingsBody extends StatefulWidget {
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
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  bool _isNotificationActionProcessing = false;

  @override
  void initState() {
    super.initState();
    _recordNotificationUiDiagnostic('diagnostic_build_marker', {
      'marker': notificationToggleDiagnosticBuildMarker,
      'location': 'settings_screen_initialization',
    });
    unawaited(
      HikeNotificationService.instance.refreshNotificationEnabledState(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ColoredBox(
      color: colors.background,
      child: ListView(
        key: const PageStorageKey<String>('settings-list'),
        padding: AppResponsive.scrollPaddingWithFloatingNav(context, top: 20),
        children: [
          _ProfileSettingsHeader(
            userName: widget.userName,
            userEmail: widget.userEmail,
            photoUrl: widget.photoUrl,
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            children: [
              const _DarkModeSettingsTile(),
              AnimatedBuilder(
                animation: HikeNotificationService.instance,
                builder: (context, _) {
                  final notificationsEnabled =
                      HikeNotificationService.instance.notificationsEnabled;
                  final ValueChanged<bool>? onNotificationChanged =
                      _isNotificationActionProcessing
                      ? null
                      : (requestedValue) {
                          _recordNotificationUiDiagnostic(
                            'diagnostic_build_marker',
                            {
                              'marker': notificationToggleDiagnosticBuildMarker,
                              'location': 'settings_switch_tap',
                            },
                          );
                          _recordNotificationUiDiagnostic(
                            'settings_switch_tap_received',
                            {
                              'requested_value': requestedValue,
                              'current_switch_value': notificationsEnabled,
                              'processing_state_before':
                                  _isNotificationActionProcessing,
                              'widget_mounted': mounted,
                            },
                          );
                          _recordNotificationUiDiagnostic(
                            'toggle_tap_received',
                            {
                              'requestedEnabled': requestedValue,
                              'visibleEnabled': notificationsEnabled,
                              'processing': _isNotificationActionProcessing,
                            },
                          );
                          unawaited(
                            _handleNotificationSwitchChange(
                              context,
                              enabled: requestedValue,
                            ),
                          );
                        };

                  return _SettingsTileShell(
                    onTap: null,
                    leading: Icon(
                      Icons.notifications_rounded,
                      color: context.appColors.accent,
                    ),
                    title: 'Notifications',
                    subtitle: notificationsEnabled
                        ? 'Hike reminders are turned on.'
                        : 'Hike reminders are turned off.',
                    trailing: _NotificationToggleButton(
                      notificationsEnabled: notificationsEnabled,
                      isProcessing: _isNotificationActionProcessing,
                      onChanged: onNotificationChanged,
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.security_rounded,
                title: 'Privacy and Security',
                subtitle: 'Manage app access and safety options',
                onTap: () => widget.onShowSnack(
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
                onTap: () => widget.onShowSnack(
                  context,
                  'Help center is ready for hookup.',
                ),
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
          if (notificationDiagnostics) ...[
            const SizedBox(height: 16),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.bug_report_rounded,
                  title: 'Notification diagnostics',
                  subtitle: 'Inspect and test the production reminder path',
                  onTap: _isNotificationActionProcessing
                      ? null
                      : () => _showNotificationDiagnostics(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleNotificationSwitchChange(
    BuildContext context, {
    required bool enabled,
  }) async {
    final stopwatch = Stopwatch()..start();
    _recordNotificationUiDiagnostic('handler_started', {
      'requested_value': enabled,
      'current_switch_value':
          HikeNotificationService.instance.notificationsEnabled,
      'processing_state_before': _isNotificationActionProcessing,
      'widget_mounted': mounted,
    });
    _recordNotificationUiDiagnostic('toggle_handler_entered', {
      'requestedEnabled': enabled,
      'visibleEnabled': HikeNotificationService.instance.notificationsEnabled,
      'processing': _isNotificationActionProcessing,
    });
    if (_isNotificationActionProcessing) {
      _recordNotificationUiDiagnostic('toggle_tap_ignored', {
        'requestedEnabled': enabled,
        'reason': 'operation-in-progress',
      });
      return;
    }

    try {
      if (enabled) {
        final result = await _runNotificationAction<NotificationEnableResult>(
          () async {
            _recordNotificationUiDiagnostic(
              'notification_service_call_started',
              {'requestedEnabled': true},
            );
            final result = await HikeNotificationService.instance
                .enableFromSettings();
            _recordNotificationUiDiagnostic('service_result_received', {
              'requestedEnabled': true,
              'success': result.enabled,
              'failureKind': result.failureKind?.name ?? 'none',
              'visibleEnabled':
                  HikeNotificationService.instance.notificationsEnabled,
            });
            _recordNotificationUiDiagnostic('handler_result', {
              'requested_value': true,
              'success': result.enabled,
              'failure_kind': result.failureKind?.name ?? 'none',
              'final_switch_value':
                  HikeNotificationService.instance.notificationsEnabled,
            });
            return result;
          },
        );
        if (result == null) {
          return;
        }
        if (context.mounted) {
          _recordNotificationUiDiagnostic('dialog_attempted', {
            'requested_value': true,
            'title': result.enabled
                ? 'Notifications Turned On'
                : 'Notifications Not Enabled',
          });
          await _showNotificationEnableResult(context, result);
        } else {
          _recordNotificationUiDiagnostic('dialog_display_skipped', {
            'reason': 'context-unmounted',
            'requestedEnabled': true,
          });
        }
        return;
      }

      final result = await _runNotificationAction<NotificationDisableResult>(
        () async {
          _recordNotificationUiDiagnostic('notification_service_call_started', {
            'requestedEnabled': false,
          });
          final result = await HikeNotificationService.instance
              .disableFromSettings();
          _recordNotificationUiDiagnostic('service_result_received', {
            'requestedEnabled': false,
            'success': result.disabled,
            'visibleEnabled':
                HikeNotificationService.instance.notificationsEnabled,
          });
          _recordNotificationUiDiagnostic('handler_result', {
            'requested_value': false,
            'success': result.disabled,
            'final_switch_value':
                HikeNotificationService.instance.notificationsEnabled,
          });
          return result;
        },
      );
      if (result == null) {
        return;
      }
      if (context.mounted) {
        _recordNotificationUiDiagnostic('dialog_attempted', {
          'requested_value': false,
          'title': result.disabled
              ? 'Notifications Turned Off'
              : 'Notifications Not Updated',
        });
        await _showNotificationDisableResult(context, result);
      } else {
        _recordNotificationUiDiagnostic('dialog_display_skipped', {
          'reason': 'context-unmounted',
          'requestedEnabled': false,
        });
      }
    } finally {
      stopwatch.stop();
      _recordNotificationUiDiagnostic('toggle_operation_finished', {
        'requestedEnabled': enabled,
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'visibleEnabled': HikeNotificationService.instance.notificationsEnabled,
        'processing': _isNotificationActionProcessing,
      });
      _recordNotificationUiDiagnostic('processing_state_after', {
        'processing_state_after': _isNotificationActionProcessing,
        'elapsed_ms': stopwatch.elapsedMilliseconds,
      });
      _recordNotificationUiDiagnostic('final_switch_value', {
        'final_switch_value':
            HikeNotificationService.instance.notificationsEnabled,
      });
    }
  }

  Future<void> _showNotificationEnableResult(
    BuildContext context,
    NotificationEnableResult result,
  ) async {
    if (result.enabled) {
      await _showNotificationStatusDialog(
        context,
        title: 'Notifications Turned On',
        message: 'You will now receive reminders for your scheduled hikes.',
      );
      return;
    }

    await _showNotificationStatusDialog(
      context,
      title: 'Notifications Not Enabled',
      message: result.message,
      showSettingsAction: result.openSettingsSuggested,
    );
  }

  Future<void> _showNotificationDisableResult(
    BuildContext context,
    NotificationDisableResult result,
  ) async {
    if (result.disabled) {
      await _showNotificationStatusDialog(
        context,
        title: 'Notifications Turned Off',
        message:
            'You will no longer receive reminders for your scheduled hikes.',
      );
      return;
    }

    await _showNotificationStatusDialog(
      context,
      title: 'Notifications Not Updated',
      message: result.message,
    );
  }

  Future<void> _showNotificationStatusDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool showSettingsAction = false,
  }) async {
    _recordNotificationUiDiagnostic('dialog_display_started', {'title': title});
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (showSettingsAction)
              TextButton(
                onPressed: () {
                  unawaited(
                    HikeNotificationService.instance.openNotificationSettings(),
                  );
                },
                child: const Text('Settings'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    _recordNotificationUiDiagnostic('dialog_display_completed', {
      'title': title,
    });
  }

  Future<void> _showNotificationDiagnostics(BuildContext context) async {
    if (!notificationDiagnostics || _isNotificationActionProcessing) {
      return;
    }

    setState(() {
      _isNotificationActionProcessing = true;
    });
    final service = HikeNotificationService.instance;
    var report = await service.collectDiagnostics();
    if (!mounted || !context.mounted) {
      return;
    }
    setState(() {
      _isNotificationActionProcessing = false;
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Notification diagnostics'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: SelectableText(
                    report.summary,
                    style: Theme.of(
                      dialogContext,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
              actions: [
                if (report.openSettingsSuggested)
                  TextButton(
                    onPressed: () {
                      unawaited(service.openNotificationSettings());
                    },
                    child: const Text('Open Settings'),
                  ),
                TextButton(
                  onPressed: () async {
                    final result = await service.runProductionDiagnosticShow();
                    final refreshed = await service.collectDiagnostics();
                    if (!dialogContext.mounted) {
                      return;
                    }
                    setDialogState(() {
                      report = NotificationDiagnosticsReport(
                        summary: '${result.message}\n\n${refreshed.summary}',
                        openSettingsSuggested: refreshed.openSettingsSuggested,
                      );
                    });
                  },
                  child: const Text('Run Show Test'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<T?> _runNotificationAction<T>(Future<T> Function() action) async {
    if (_isNotificationActionProcessing) {
      return null;
    }

    setState(() {
      _isNotificationActionProcessing = true;
    });
    _recordNotificationUiDiagnostic('toggle_processing_state_changed', {
      'processing': true,
      'visibleEnabled': HikeNotificationService.instance.notificationsEnabled,
    });

    try {
      return await action();
    } catch (error, stackTrace) {
      debugPrint(
        '[HikeNotifications] settings_action_failed '
        'errorType=${error.runtimeType} error=$error',
      );
      debugPrintStack(
        label: '[HikeNotifications] settings_action_stack',
        stackTrace: stackTrace,
      );
      if (mounted) {
        widget.onShowSnack(
          context,
          'Notification setting could not be updated: $error',
        );
      }
      return null;
    } finally {
      _recordNotificationUiDiagnostic('processing_cleanup_started', {
        'processing_state_before': _isNotificationActionProcessing,
        'final_switch_value':
            HikeNotificationService.instance.notificationsEnabled,
      });
      if (mounted) {
        setState(() {
          _isNotificationActionProcessing = false;
        });
        _recordNotificationUiDiagnostic('toggle_processing_state_changed', {
          'processing': false,
          'visibleEnabled':
              HikeNotificationService.instance.notificationsEnabled,
        });
      } else {
        _isNotificationActionProcessing = false;
      }
      _recordNotificationUiDiagnostic('processing_state_cleared', {
        'processing_state_after': _isNotificationActionProcessing,
        'final_switch_value':
            HikeNotificationService.instance.notificationsEnabled,
      });
      _recordNotificationUiDiagnostic('processing_cleanup_completed', {
        'processing_state_after': _isNotificationActionProcessing,
        'final_switch_value':
            HikeNotificationService.instance.notificationsEnabled,
        'widget_mounted': mounted,
      });
    }
  }

  void _recordNotificationUiDiagnostic(
    String event, [
    Map<String, Object?> fields = const <String, Object?>{},
  ]) {
    final values = fields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    final details = values.isEmpty ? '' : ' $values';
    debugPrint(
      '[HikeNotifications] $event '
      'timestamp=${DateTime.now().toUtc().toIso8601String()}$details',
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

class _NotificationToggleButton extends StatelessWidget {
  const _NotificationToggleButton({
    required this.notificationsEnabled,
    required this.isProcessing,
    required this.onChanged,
  });

  final bool notificationsEnabled;
  final bool isProcessing;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 64,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Switch(
            value: notificationsEnabled,
            onChanged: onChanged,
            activeColor: colors.primary,
            activeTrackColor: colors.accent.withValues(alpha: 0.72),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colors.surfaceMuted,
          ),
          if (isProcessing)
            Positioned(
              right: 0,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: notificationsEnabled ? colors.primary : colors.accent,
                ),
              ),
            ),
        ],
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
  final VoidCallback? onTap;

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
