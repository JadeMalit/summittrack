class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const profile = '/profile';
  static const settings = '/settings';

  static const mtApoMountainId = 'mt-apo';
  static const mtPulagMountainId = 'mt-pulag';
  static const staCruzTrailId = 'sta-cruz-sibulan';

  static String mountain(String mountainId) => '/mountain/$mountainId';

  static String trail(String mountainId, String trailId) =>
      '${mountain(mountainId)}/trail/$trailId';

  static String loginWithRedirect(String redirectTo) =>
      _routeWithRedirect(login, redirectTo);

  static String signupWithRedirect(String redirectTo) =>
      _routeWithRedirect(signup, redirectTo);

  static String normalizeLocation(String? location) {
    if (location == null || location.trim().isEmpty) {
      return home;
    }

    final uri = Uri.parse(location);
    final normalizedPath = uri.path.isEmpty ? home : uri.path;

    return uri.replace(path: normalizedPath).toString();
  }

  static String resolveRedirectTarget(String? redirectTo) {
    final normalized = normalizeLocation(redirectTo);
    final uri = Uri.parse(normalized);
    final path = uri.path;

    if (path == login || path == signup) {
      return home;
    }

    return normalized;
  }

  static String? redirectFromUri(Uri uri) {
    final redirect = uri.queryParameters['from'];
    if (redirect == null || redirect.isEmpty) {
      return null;
    }

    return resolveRedirectTarget(redirect);
  }

  static String _routeWithRedirect(String path, String redirectTo) {
    final target = resolveRedirectTarget(redirectTo);
    if (target == home) {
      return path;
    }

    return Uri(
      path: path,
      queryParameters: {'from': target},
    ).toString();
  }
}
