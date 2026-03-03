import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/platform/platform_window.dart';
import 'core/storage/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Hive cache system
  await CacheManager.init();

  // Initialize dependency injection
  await initDependencies();

  // Platform-aware window configuration
  // (portrait-only on mobile, all orientations on desktop/web)
  await PlatformWindow.configure();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MdfApp(),
    ),
  );
}
