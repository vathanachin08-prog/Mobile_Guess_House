import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'binding/initial_binding.dart';
import 'routes/app_route.dart';
import 'routes/app_route_name.dart';
import 'translations/messages.dart';
import 'widgets/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/firebase_service.dart';
import 'core/services/language_service.dart';
import 'data/local/token_store_local.dart';
import 'widgets/ios_device_preview_toolbar.dart';

Future<void> main() async {
  // Initialize DevicePreview simulation (Web and Debug/Profile)
  DevicePreview.enable(
    enabled: kIsWeb || !kReleaseMode,
    padding: const EdgeInsets.all(16),
  );

  await GetStorage.init();
  TokenStoreLocal.initTokenListener();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Remote Config
  await AppFirebaseService.initRemoteConfig();

  // On Web, start with iPhone 16 Pro simulation by default
  if (kIsWeb) {
    DevicePreview.maybeController?.applyPreset(DevicePresets.iPhone16Pro);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RoomFinder KH - Rental Marketplace',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        AppFirebaseService.observer,
      ],
      translations: Messages(),
      locale: LanguageService.getInitialLocale(),
      fallbackLocale: LanguageService.englishLocale,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 320),
      builder: (context, child) {
        if (kIsWeb) {
          return Stack(
            children: [
              ?child,
              const IosDevicePreviewToolbar(),
            ],
          );
        }
        return child ?? const SizedBox.shrink();
      },
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          surfaceContainerLowest: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      initialRoute: AppRouteName.splash,
      unknownRoute: AppRoute.getAllRoutes().first,
      initialBinding: InitialBinding(),
      getPages: AppRoute.getAllRoutes(),
    );
  }
}
