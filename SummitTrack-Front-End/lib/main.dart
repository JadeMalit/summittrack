import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'core/connectivity/internet_status_controller.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_route_observer.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImagePicker();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeController.instance.load();

  runApp(const SummitTrackApp());
}

void _configureImagePicker() {
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
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
          navigatorKey: appNavigatorKey,
          navigatorObservers: [appRouteObserver],
          onGenerateRoute: AppRouter.onGenerateRoute,
          onGenerateInitialRoutes: AppRouter.onGenerateInitialRoutes,
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
