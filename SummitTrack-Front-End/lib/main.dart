import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeController.instance.load();

  runApp(const SummitTrackApp());
}

class SummitTrackApp extends StatelessWidget {
  const SummitTrackApp({super.key});

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
          onGenerateRoute: AppRouter.onGenerateRoute,
          onGenerateInitialRoutes: AppRouter.onGenerateInitialRoutes,
          onUnknownRoute: AppRouter.onUnknownRoute,
        );
      },
    );
  }
}
