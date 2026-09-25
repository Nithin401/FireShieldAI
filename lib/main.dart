import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/emergency_dispatch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Emergency Contacts & Settings
  await EmergencyDispatchService().initialize();
  
  // Initialize Firebase for project smart-fire-detection-272bb
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialized for project: smart-fire-detection-272bb');
  } catch (e) {
    debugPrint('ℹ️ Firebase initialization note: $e');
  }
  
  runApp(
    const ProviderScope(
      child: FireShieldApp(),
    ),
  );
}

class FireShieldApp extends ConsumerWidget {
  const FireShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'FireShield AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Adapts to device theme
      routerConfig: router,
    );
  }
}
