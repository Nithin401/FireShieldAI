import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/presentation/features/notifications/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(mockNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(mockNotificationsProvider.notifier).markAllAsRead();
            },
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text('No new notifications.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                
                Color iconColor = AppColors.info;
                IconData iconData = Icons.info_outline;
                
                if (notif.severity == 'critical') {
                  iconColor = AppColors.error;
                  iconData = Icons.error_outline;
                } else if (notif.severity == 'warning') {
                  iconColor = AppColors.warning;
                  iconData = Icons.warning_amber_outlined;
                }

                return Card(
                  elevation: notif.isRead ? 1 : 4,
                  color: notif.isRead 
                      ? Theme.of(context).cardColor.withValues(alpha: 0.7)
                      : Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withValues(alpha: 0.1),
                      child: Icon(iconData, color: iconColor),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(notif.message),
                        const SizedBox(height: 8),
                        Text(
                          '${notif.timestamp.hour}:${notif.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
