import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/domain/models/notification_model.dart';

class LiveAlertsFeedCard extends StatelessWidget {
  final List<NotificationModel> alerts;
  final ValueChanged<String> onAcknowledge;
  final VoidCallback onViewAll;

  const LiveAlertsFeedCard({
    super.key,
    required this.alerts,
    required this.onAcknowledge,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live Incidents & Audit Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All ↗',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text(
                'No active emergency alerts. All zones nominal.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.take(4).length,
              separatorBuilder: (context, index) => const Divider(
                color: Color(0xFF334155),
                height: 16,
              ),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final isCritical = alert.severity == 'critical';
                final isWarning = alert.severity == 'warning';
                final badgeColor = isCritical
                    ? AppColors.error
                    : (isWarning ? AppColors.warning : const Color(0xFF38BDF8));

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCritical
                            ? Icons.local_fire_department
                            : (isWarning ? Icons.warning_amber : Icons.info_outline),
                        color: badgeColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                alert.roomId ?? 'Zone Monitored',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTime(alert.timestamp),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (alert.fireAngle != null)
                                Text(
                                  'Aim: ${alert.fireAngle}° | Risk: ${alert.riskScore?.toStringAsFixed(0) ?? 0}%',
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              if (!alert.isRead)
                                InkWell(
                                  onTap: () => onAcknowledge(alert.id),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.error.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: const Text(
                                      'ACKNOWLEDGE',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.success, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'ACKNOWLEDGED',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
