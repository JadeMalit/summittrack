import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final AppRouteObserver appRouteObserver = AppRouteObserver();

class AppRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  final List<Route<dynamic>> _routes = <Route<dynamic>>[];

  String? get currentRouteName {
    for (var index = _routes.length - 1; index >= 0; index--) {
      final route = _routes[index];
      if (route is PageRoute<dynamic>) {
        return route.settings.name;
      }
    }

    return null;
  }

  bool get isPopupRouteOnTop {
    return _routes.isNotEmpty && _routes.last is PopupRoute<dynamic>;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (oldRoute != null) {
      _routes.remove(oldRoute);
    }

    if (newRoute != null) {
      _trackRoute(newRoute);
    }
  }

  void _trackRoute(Route<dynamic> route) {
    if (route is! PageRoute<dynamic> && route is! PopupRoute<dynamic>) {
      return;
    }

    _routes
      ..remove(route)
      ..add(route);
  }
}
