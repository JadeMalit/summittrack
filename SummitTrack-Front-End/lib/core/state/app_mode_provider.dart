import 'package:flutter/foundation.dart';

import '../routing/app_routes.dart';

enum AppMode { online, offline }

class AppModeProvider extends ChangeNotifier {
  AppModeProvider._();

  static final AppModeProvider instance = AppModeProvider._();

  AppMode _mode = AppMode.online;
  bool _showSignInAfterOfflineMode = false;
  String? _previousOnlineRoute;

  AppMode get mode => _mode;

  bool get isOfflineMode => _mode == AppMode.offline;

  bool get isOnlineMode => _mode == AppMode.online;

  bool get shouldShowSignInAfterOfflineMode => _showSignInAfterOfflineMode;

  String get previousOnlineRoute => _previousOnlineRoute ?? AppRoutes.home;

  void enableOfflineMode() {
    _setMode(AppMode.offline);
  }

  void disableOfflineMode() {
    _setMode(AppMode.online);
  }

  void requestSignInAfterOfflineMode() {
    _showSignInAfterOfflineMode = true;
  }

  void clearSignInAfterOfflineModeRequest() {
    _showSignInAfterOfflineMode = false;
  }

  void rememberPreviousOnlineRoute(String? routeName) {
    final normalized = AppRoutes.normalizeLocation(routeName);
    final path = Uri.parse(normalized).path;

    if (path == AppRoutes.login ||
        path == AppRoutes.signup ||
        path == '/forgot-password') {
      return;
    }

    _previousOnlineRoute = normalized;
  }

  bool isRouteAllowedInOfflineMode(String? routeName) {
    final location = AppRoutes.normalizeLocation(routeName);
    final uri = Uri.parse(location);
    final path = uri.path;

    if (path == AppRoutes.home || path == '/home') {
      return true;
    }

    if (path == AppRoutes.login) {
      return true;
    }

    return uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'mountain';
  }

  void _setMode(AppMode mode) {
    if (_mode == mode) {
      return;
    }

    _mode = mode;
    notifyListeners();
  }
}
