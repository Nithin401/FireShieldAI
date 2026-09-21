import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

/// Primary In-App & Native Push Notification Service for FireShield AI
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  final Set<String> _dispatchedAlertIds = {};

  Future<void> initialize() async {
    requestNotificationPermission();
    debugPrint("✅ FireShield AI In-App & Push Notification Engine Initialized.");
  }

  /// Dispatches a high-priority notification directly from the app
  void dispatchAppNotification({
    required String id,
    required String title,
    required String message,
    required String severity,
    BuildContext? context,
    VoidCallback? onAcknowledge,
    VoidCallback? onInspect,
  }) {
    // Prevent duplicated popups for the exact same alert event ID
    if (_dispatchedAlertIds.contains(id)) {
      return;
    }
    _dispatchedAlertIds.add(id);

    // 1. Trigger Native System / Browser Notification & Siren Sound
    triggerSystemNotification(title, message, severity);

    // 2. If in foreground context, display interactive Emergency Heads-Up Overlay
    if (context != null && context.mounted) {
      final isCritical = severity == 'critical' || severity == 'fire';
      final alertColor = isCritical ? AppColors.error : AppColors.warning;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: isCritical ? 8 : 4),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: alertColor, width: 2),
          ),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCritical ? Icons.local_fire_department : Icons.warning_amber,
                  color: alertColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: alertColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'ACKNOWLEDGE',
            textColor: Colors.white,
            backgroundColor: alertColor,
            onPressed: () {
              onAcknowledge?.call();
            },
          ),
        ),
      );
    }
  }

  void simulateIncomingFireAlert(BuildContext context, String deviceId) {
    dispatchAppNotification(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      title: '🔥 CRITICAL FIRE ALERT: $deviceId',
      message: 'Abnormal thermal spike on $deviceId. Evacuate immediately!',
      severity: 'critical',
      context: context,
    );
  }
}
