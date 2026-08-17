import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Init (Web/Mobile)
  // Firebase Core & Crashlytics, Analytics 設定の準備
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   debugPrint('Firebase init note: $e');
  // }

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
