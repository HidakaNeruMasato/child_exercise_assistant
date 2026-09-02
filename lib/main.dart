import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routing/app_router.dart';
import 'services/crashlytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Core & Crashlytics, Analytics 設定
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await CrashlyticsService.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase initialization note: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: ChildExerciseAssistantApp(),
    ),
  );
}

class ChildExerciseAssistantApp extends ConsumerWidget {
  const ChildExerciseAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
