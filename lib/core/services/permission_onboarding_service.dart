import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

/// Manages first-launch emergency permissions onboarding for FireShield AI
class PermissionOnboardingService {
  static const String _prefKey = 'fireshield_permissions_prompted_v1';

  /// Evaluates permissions and displays the Play-Store ready emergency modal if ungranted
  static Future<void> checkAndPromptPermissions(BuildContext context) async {
    if (kIsWeb) {
      // On Web, request browser notification permission directly
      requestNotificationPermission();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyPrompted = prefs.getBool(_prefKey) ?? false;

      // Check current permission statuses
      final notifStatus = await Permission.notification.status;
      final phoneStatus = await Permission.phone.status;

      // If already granted, no need to disturb user
      if (notifStatus.isGranted && phoneStatus.isGranted) {
        return;
      }

      // If unprompted or missing critical permissions, display the UI modal
      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        isDismissible: !alreadyPrompted,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0F172A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) => _PermissionOnboardingModal(
          onGrant: () async {
            Navigator.of(ctx).pop();
            await prefs.setBool(_prefKey, true);
            await _requestAllPermissions();
          },
          onDismiss: () async {
            Navigator.of(ctx).pop();
            await prefs.setBool(_prefKey, true);
          },
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error during permission prompt flow: $e');
    }
  }

  static Future<void> _requestAllPermissions() async {
    try {
      // 1. Notification (Lockscreen sirens & push alerts)
      await Permission.notification.request();

      // 2. Direct Call (Autonomous dialer upon 30s timeout)
      await Permission.phone.request();

      // 3. Direct SMS (Autonomous telemetry transmission)
      await Permission.sms.request();

      // Ensure notification channel is initialized
      requestNotificationPermission();
    } catch (e) {
      debugPrint('⚠️ Error requesting permissions: $e');
    }
  }
}

class _PermissionOnboardingModal extends StatelessWidget {
  final VoidCallback onGrant;
  final VoidCallback onDismiss;

  const _PermissionOnboardingModal({
    required this.onGrant,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Icon & Badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0x33EF4444), Color(0x00EF4444)],
                  radius: 0.8,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Emergency Life-Safety Permissions',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'FireShield AI acts autonomously when danger is detected. To sound loud sirens on your lockscreen and dial emergency contacts, the app requires your permission:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Feature list cards
          _buildPermissionItem(
            icon: Icons.notifications_active,
            title: 'Critical Lockscreen Alarms',
            description: 'Wakes up your locked screen and sounds sirens even when the app is closed or phone is on silent.',
            badgeColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),

          _buildPermissionItem(
            icon: Icons.phone_forwarded,
            title: 'Direct Emergency Calling',
            description: 'Automatically places a direct call to your emergency contact or 101 Fire Department if an alarm is unverified after 30 seconds.',
            badgeColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 12),

          _buildPermissionItem(
            icon: Icons.sms_outlined,
            title: 'Autonomous SOS Dispatch',
            description: 'Sends real-time temperature, flame bearing angle, and GPS coordinates to responders.',
            badgeColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),

          // Grant Access Button
          ElevatedButton(
            onPressed: onGrant,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Grant Emergency Access',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Maybe later button
          TextButton(
            onPressed: onDismiss,
            child: const Text(
              'Remind Me Later',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
