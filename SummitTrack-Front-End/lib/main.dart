import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'core/connectivity/internet_status_controller.dart';
import 'core/routing/app_route_observer.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/mountains/screens/live_hike_viewer_screen.dart';
import 'features/notifications/services/hike_notification_service.dart';
import 'firebase_options.dart';

const String _startupLogPrefix = '[SummitTrackStartup]';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _logStartup('Flutter binding initialized');
  _configureImagePicker();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _logStartup('Firebase initialized');
  _registerNotificationBackgroundHandlerSafely();
  await ThemeController.instance.load();
  _logStartup('Theme preference loaded');

  _logStartup('runApp called');
  runApp(const SummitTrackApp());
  initializeNotificationsAfterFirstFrame();
}

void _configureImagePicker() {
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
}

void _registerNotificationBackgroundHandlerSafely() {
  try {
    FirebaseMessaging.onBackgroundMessage(
      summitTrackFirebaseMessagingBackgroundHandler,
    );
    _logStartup('Firebase Messaging background handler registered');
  } catch (error, stackTrace) {
    _logStartup(
      'Firebase Messaging background handler registration failed '
      'error=${error.runtimeType}',
    );
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

@visibleForTesting
void initializeNotificationsAfterFirstFrame({
  Future<void> Function()? initialize,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _logStartup(
      'First frame rendered '
      'route=${appRouteObserver.currentRouteName ?? 'unresolved'}',
    );
    unawaited(_initializeNotificationsSafely(initialize: initialize));
  });
}

Future<void> _initializeNotificationsSafely({
  Future<void> Function()? initialize,
}) async {
  _logStartup('Notification service initialization started');
  try {
    await (initialize ?? HikeNotificationService.instance.initialize)();
    _logStartup('Notification service initialization completed');
  } catch (error, stackTrace) {
    _logStartup(
      'Notification service initialization failed '
      'error=${error.runtimeType}; app startup continues',
    );
    if (kDebugMode || notificationDiagnostics) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

void _logStartup(String message) {
  debugPrint('$_startupLogPrefix $message');
}

class SummitTrackApp extends StatefulWidget {
  const SummitTrackApp({super.key});

  @override
  State<SummitTrackApp> createState() => _SummitTrackAppState();
}

class _SummitTrackAppState extends State<SummitTrackApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledHikeId;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      _logStartup('Failed to get initial deep link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        _logStartup('Deep Link Stream error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    _logStartup('Deep link received: $uri');

    String? hikeId = uri.queryParameters['hikeId'];

    if (hikeId == null || hikeId.isEmpty) {
      final rawUri = uri.toString();
      if (rawUri.contains('hikeId=')) {
        final split = rawUri.split('hikeId=');
        if (split.length > 1) {
          hikeId = Uri.decodeComponent(split[1].split('&').first);
        }
      }
    }

    if (hikeId != null && hikeId.isNotEmpty) {
      if (_lastHandledHikeId == hikeId) {
        return;
      }
      _lastHandledHikeId = hikeId;

      _logStartup('Navigating to LiveHikeViewerScreen with hikeId: $hikeId');
      final targetHikeId = hikeId;

      void performNavigation() {
        final navigator = appNavigatorKey.currentState;
        if (navigator != null) {
          navigator.push(
            MaterialPageRoute(
              settings: RouteSettings(name: '/track?hikeId=$targetHikeId'),
              builder: (context) => LiveHikeViewerScreen(hikeId: targetHikeId),
            ),
          );
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => performNavigation());
      Future.delayed(const Duration(milliseconds: 350), performNavigation);
      Future.delayed(const Duration(seconds: 3), () {
        _lastHandledHikeId = null;
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SummitTrack',
          themeMode: themeController.themeMode,
          themeAnimationDuration: AppTheme.animationDuration,
          themeAnimationCurve: AppTheme.animationCurve,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          navigatorKey: appNavigatorKey,
          navigatorObservers: [appRouteObserver],
          onGenerateRoute: AppRouter.onGenerateRoute,
          onGenerateInitialRoutes: (initialRoute) {
            _logStartup('Initial route selected route=$initialRoute');
            return AppRouter.onGenerateInitialRoutes(initialRoute);
          },
          onUnknownRoute: AppRouter.onUnknownRoute,
          builder: (context, child) {
            return InternetStatusController(
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}