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
        title: const Text('Live Incident Alerts'),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(mockNotificationsProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All alerts marked as acknowledged.')),
              );
            },
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text(
              'Acknowledge All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No active fire alerts or warnings.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
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
                  iconData = Icons.local_fire_department;
                } else if (notif.severity == 'warning') {
                  iconColor = AppColors.warning;
                  iconData = Icons.warning_amber_outlined;
                }

                return Card(
                  elevation: notif.isRead ? 1 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: notif.isRead
                          ? Colors.transparent
                          : iconColor.withValues(alpha: 0.5),
                      width: notif.isRead ? 0 : 1.5,
                    ),
                  ),
                  color: notif.isRead
                      ? Theme.of(context).cardColor.withValues(alpha: 0.7)
                      : Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: iconColor.withValues(alpha: 0.15),
                              radius: 22,
                              child: Icon(iconData, color: iconColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: notif.isRead
                                              ? Colors.grey.withValues(alpha: 0.2)
                                              : iconColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          notif.isRead ? 'RESOLVED' : notif.severity.toUpperCase(),
                                          style: TextStyle(
                                            color: notif.isRead ? Colors.grey : iconColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif.message,
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Telemetry badging if present
                        if (notif.roomId != null || notif.riskScore != null || notif.fireAngle != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (notif.roomId != null)
                                Chip(
                                  avatar: const Icon(Icons.room, size: 14),
                                  label: Text(notif.roomId!, style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              if (notif.riskScore != null)
                                Chip(
                                  avatar: const Icon(Icons.analytics_outlined, size: 14),
                                  label: Text('Risk: ${notif.riskScore!.toStringAsFixed(1)}%',
                                      style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              if (notif.fireAngle != null)
                                Chip(
                                  avatar: const Icon(Icons.explore_outlined, size: 14),
                                  label: Text('Aim: ${notif.fireAngle}°',
                                      style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')} • '
                              '${notif.timestamp.year}-${notif.timestamp.month.toString().padLeft(2, '0')}-${notif.timestamp.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (!notif.isRead)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: iconColor,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('ACKNOWLEDGE', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  await ref.read(mockNotificationsProvider.notifier).acknowledge(notif.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Alert "${notif.title}" acknowledged.'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
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

