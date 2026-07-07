import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (mocked for now, until Milestone 11)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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
