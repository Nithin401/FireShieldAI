import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/signup_screen.dart';
import '../../presentation/features/auth/forgot_password_screen.dart';
import '../../presentation/features/dashboard/dashboard_screen.dart';
import '../../presentation/common/widgets/main_layout.dart';
import '../../presentation/features/device/device_list_screen.dart';
import '../../presentation/features/device/add_device_screen.dart';
import '../../presentation/features/device/device_details_screen.dart';
import '../../presentation/features/map/map_screen.dart';
import '../../presentation/features/notifications/notifications_screen.dart';
import '../../presentation/features/reports/reports_screen.dart';
import '../../presentation/features/settings/settings_screen.dart';
import '../../presentation/features/settings/profile_screen.dart';
import '../../presentation/providers/repository_providers.dart';

// Strict Auth-Guarded Router: Unauthenticated users CANNOT access protected routes
final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final userId = authState.asData?.value ?? authRepo.currentUserId;
      final bool isAuthenticated = userId != null && userId.isNotEmpty;
      final path = state.uri.path;
      final bool isAuthRoute = path == '/login' || path == '/signup' || path == '/forgot-password';

      // If user is not authenticated and trying to view dashboard or app screens -> redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // If user is authenticated and navigating to login/signup -> forward to dashboard
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/devices',
            name: 'devices',
            builder: (context, state) => const DeviceListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add_device',
                builder: (context, state) => const AddDeviceScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'device_details',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DeviceDetailsScreen(deviceId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
