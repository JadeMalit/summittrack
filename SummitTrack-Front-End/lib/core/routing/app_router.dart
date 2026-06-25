import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/trail_data/Sta.Cruz details.dart';
import 'app_routes.dart';
import '../../features/auth/screens/SignIN_SignUP/pre_hike_loading_screen.dart';
import '../../features/auth/screens/SignIN_SignUP/signin.dart';
import '../../features/auth/screens/SignIN_SignUP/signup.dart';
import '../../features/auth/widgets/video_background.dart';
import '../../features/dashboard/screens/home.dart';
import '../../features/mountains/screens/kapatagan_trail_details.dart';
import '../../features/mountains/screens/mountain_detail_screen.dart';
import '../../features/mountains/screens/mt_apo.dart';
import '../../features/mountains/screens/trail_detail_screen.dart';
import '../../features/profile/screens/profile.dart';
import '../../features/settings/screens/settings.dart';
import '../../services/data_service.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final location = AppRoutes.normalizeLocation(settings.name);
    final uri = Uri.parse(location);
    final segments = uri.pathSegments;

    if (uri.path == AppRoutes.home) {
      return _route(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: true,
          child: const HomeScreen(),
        ),
      );
    }

    if (uri.path == AppRoutes.login) {
      return _authRoute(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: false,
          redirectTo: AppRoutes.redirectFromUri(uri),
          child: SignInScreen(
            redirectTo: AppRoutes.redirectFromUri(uri) ?? AppRoutes.home,
          ),
        ),
      );
    }

    if (uri.path == AppRoutes.signup) {
      return _authRoute(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: false,
          redirectTo: AppRoutes.redirectFromUri(uri),
          child: SignUpScreen(
            redirectTo: AppRoutes.redirectFromUri(uri) ?? AppRoutes.home,
          ),
        ),
      );
    }

    if (uri.path == AppRoutes.profile) {
      return _route(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: true,
          child: const ProfileScreen(),
        ),
      );
    }

    if (uri.path == AppRoutes.settings) {
      return _route(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: true,
          child: const SettingsScreen(),
        ),
      );
    }

    if (segments.length == 2 && segments.first == 'mountain') {
      final mountainId = segments[1];

      if (mountainId == AppRoutes.mtApoMountainId) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtApoScreen(),
          ),
        );
      }

      if (mountainId == AppRoutes.mtPulagMountainId) {
        final mountain = DataService.getMountains().firstWhere(
          (mountain) => mountain.name == 'Mt. Pulag',
        );

        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: MountainDetailScreen(mountain: mountain),
          ),
        );
      }
    }

    if (segments.length == 4 &&
        segments.first == 'mountain' &&
        segments[2] == 'trail') {
      final mountainId = segments[1];
      final trailId = segments[3];

      if (mountainId == AppRoutes.mtApoMountainId &&
          trailId == AppRoutes.staCruzTrailId) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: TrailDetailScreen(
              trail: staCruzSibulanTrail,
              parentRoute: AppRoutes.mountain(mountainId),
            ),
          ),
        );
      }

      if (mountainId == AppRoutes.mtApoMountainId &&
          trailId == AppRoutes.kapataganTrailId) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const KapataganTrailDetailsScreen(),
          ),
        );
      }
    }

    return onUnknownRoute(settings);
  }

  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) {
    return [onGenerateRoute(RouteSettings(name: initialRoute))];
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _route(
      settings,
      _UnknownRouteScreen(
        attemptedLocation: AppRoutes.normalizeLocation(settings.name),
      ),
    );
  }

  static PageRouteBuilder<dynamic> _authRoute(
    RouteSettings settings,
    Widget child,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) => ColoredBox(
        color: VideoBackground.fallbackBackgroundColor,
        child: child,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }

  static MaterialPageRoute<dynamic> _route(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}

Future<void>? _authBootstrapFuture;
bool _authBootstrapComplete = false;

Future<void> _ensureAuthBootstrap() {
  if (_authBootstrapComplete) {
    return SynchronousFuture<void>(null);
  }

  return _authBootstrapFuture ??= _bootstrapAuth().then<void>((_) {
    _authBootstrapComplete = true;
  });
}

Future<void> _bootstrapAuth() async {
  final auth = FirebaseAuth.instance;

  if (kIsWeb) {
    await auth.setPersistence(Persistence.LOCAL);
  }

  if (auth.currentUser != null) {
    return;
  }

  await auth.authStateChanges().first;
}

class _AuthGuard extends StatefulWidget {
  const _AuthGuard({
    required this.currentLocation,
    required this.requireAuth,
    required this.child,
    this.redirectTo,
  });

  final String currentLocation;
  final bool requireAuth;
  final Widget child;
  final String? redirectTo;

  @override
  State<_AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<_AuthGuard> {
  Future<void>? _bootstrapFuture;
  late final bool _bootstrapAlreadyComplete;

  @override
  void initState() {
    super.initState();
    _bootstrapAlreadyComplete = _authBootstrapComplete;
    if (!_bootstrapAlreadyComplete) {
      _bootstrapFuture = _ensureAuthBootstrap();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapAlreadyComplete) {
      return _buildWithAuthState();
    }

    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AuthLoadingScreen();
        }

        return _buildWithAuthState();
      },
    );
  }

  Widget _buildWithAuthState() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (widget.requireAuth) {
          if (user != null) {
            return widget.child;
          }

          return _RouteRedirect(
            targetLocation: AppRoutes.loginWithRedirect(widget.currentLocation),
          );
        }

        if (user != null) {
          final isLoginRoute =
              Uri.parse(widget.currentLocation).path == AppRoutes.login;
          if (isLoginRoute && PreHikeLoginTransition.isActive) {
            return widget.child;
          }

          return _RouteRedirect(
            targetLocation: AppRoutes.resolveRedirectTarget(widget.redirectTo),
          );
        }

        return widget.child;
      },
    );
  }
}

class _RouteRedirect extends StatefulWidget {
  const _RouteRedirect({required this.targetLocation});

  final String targetLocation;

  @override
  State<_RouteRedirect> createState() => _RouteRedirectState();
}

class _RouteRedirectState extends State<_RouteRedirect> {
  bool _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_redirected) {
      return;
    }

    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(widget.targetLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _AuthLoadingScreen();
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: VideoBackground.fallbackBackgroundColor,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.attemptedLocation});

  final String attemptedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 54),
              const SizedBox(height: 16),
              Text(
                'No screen is registered for "$attemptedLocation".',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
