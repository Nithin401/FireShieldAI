import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/core/services/push_notification_service.dart';
import 'package:fireshield_app/presentation/features/notifications/providers/notification_providers.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    PushNotificationService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for real-time alerts across all app screens
    ref.listen(mockNotificationsProvider, (previous, next) {
      final unreadCriticals = next.where((n) => !n.isRead && (n.severity == 'critical' || n.severity == 'warning')).toList();
      for (final alert in unreadCriticals) {
        PushNotificationService().dispatchAppNotification(
          id: alert.id,
          title: alert.title,
          message: alert.message,
          severity: alert.severity,
          context: context,
          onAcknowledge: () {
            ref.read(mockNotificationsProvider.notifier).acknowledge(alert.id);
          },
        );
      }
    });

    final notifications = ref.watch(mockNotificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead && n.severity == 'critical').length;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (int index) => _onItemTapped(index, context),
        destinations: [
          NavigationDestination(
            icon: unreadCount > 0
                ? Badge.count(
                    count: unreadCount,
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.dashboard_outlined),
                  )
                : const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other),
            label: 'Devices',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/devices')) {
      return 1;
    }
    if (location.startsWith('/map')) {
      return 2;
    }
    if (location.startsWith('/reports')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0; // Default to Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/devices');
        break;
      case 2:
        context.go('/map');
        break;
      case 3:
        context.go('/reports');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}
