import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const _darkModeKey = 'summittrack_dark_mode';

  bool _isDarkMode = false;
  bool _isChangingTheme = false;
  bool _hasLoaded = false;
  bool? _queuedDarkModeSave;
  Future<void>? _saveOperation;
  Timer? _themeChangeTimer;
  SharedPreferences? _preferences;
  final ValueNotifier<bool> _isChangingThemeNotifier = ValueNotifier(false);

  bool get isDarkMode => _isDarkMode;

  bool get isChangingTheme => _isChangingTheme;

  ValueListenable<bool> get isChangingThemeListenable =>
      _isChangingThemeNotifier;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    if (_hasLoaded) {
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    _isDarkMode = _preferences?.getBool(_darkModeKey) ?? false;
    _hasLoaded = true;
  }

  Future<bool> toggleDarkMode() async {
    return setDarkMode(!_isDarkMode);
  }

  Future<bool> setDarkMode(bool isDarkMode) {
    if (_isDarkMode == isDarkMode) {
      return SynchronousFuture(false);
    }

    _isDarkMode = isDarkMode;
    _startThemeChangeWindow();
    notifyListeners();
    _queueDarkModeSave(isDarkMode);

    return SynchronousFuture(true);
  }

  void _startThemeChangeWindow() {
    _themeChangeTimer?.cancel();

    if (!_isChangingTheme) {
      _isChangingTheme = true;
      _isChangingThemeNotifier.value = true;
    }

    _themeChangeTimer = Timer(AppTheme.animationDuration, () {
      _isChangingTheme = false;
      _isChangingThemeNotifier.value = false;
    });
  }

  void _queueDarkModeSave(bool isDarkMode) {
    _queuedDarkModeSave = isDarkMode;
    _saveOperation ??= _flushDarkModeSaveQueue();
  }

  Future<void> _flushDarkModeSaveQueue() async {
    while (_queuedDarkModeSave != null) {
      final isDarkMode = _queuedDarkModeSave!;
      _queuedDarkModeSave = null;

      try {
        await _saveDarkMode(isDarkMode);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'theme_controller',
            context: ErrorDescription('saving the selected theme'),
          ),
        );
      }
    }

    _saveOperation = null;
  }

  Future<void> _saveDarkMode(bool isDarkMode) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, isDarkMode);
  }

  @override
  void dispose() {
    _themeChangeTimer?.cancel();
    _isChangingThemeNotifier.dispose();
    super.dispose();
  }
}
