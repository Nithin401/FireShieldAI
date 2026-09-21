import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/core/services/emergency_dispatch_service.dart';

class HomeVerificationDialog extends StatelessWidget {
  final String roomId;
  final double temperature;
  final int fireAngle;
  final double riskScore;
  final String email;
  final String phone;
  final VoidCallback onIssueCleared;
  final VoidCallback onEmergencyConfirmed;

  const HomeVerificationDialog({
    super.key,
    required this.roomId,
    required this.temperature,
    required this.fireAngle,
    required this.riskScore,
    required this.email,
    required this.phone,
    required this.onIssueCleared,
    required this.onEmergencyConfirmed,
  });

  static Future<void> show({
    required BuildContext context,
    required String roomId,
    required double temperature,
    required int fireAngle,
    required double riskScore,
    required String email,
    required String phone,
    required VoidCallback onIssueCleared,
    required VoidCallback onEmergencyConfirmed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HomeVerificationDialog(
        roomId: roomId,
        temperature: temperature,
        fireAngle: fireAngle,
        riskScore: riskScore,
        email: email,
        phone: phone,
        onIssueCleared: () {
          Navigator.of(ctx).pop();
          onIssueCleared();
        },
        onEmergencyConfirmed: () {
          Navigator.of(ctx).pop();
          onEmergencyConfirmed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department, color: AppColors.error, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOME SAFETY CHECK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Abnormal Heat & Fire Detected',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Telemetry Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Monitored Zone:', roomId, Colors.white),
                const SizedBox(height: 6),
                _buildInfoRow('Abnormal Temperature:', '${temperature.toStringAsFixed(1)} °C', AppColors.error),
                const SizedBox(height: 6),
                _buildInfoRow('Threat Bearing / Angle:', '$fireAngle°', const Color(0xFF38BDF8)),
                const SizedBox(height: 6),
                _buildInfoRow('AI Risk Score:', '${riskScore.toStringAsFixed(1)}%', AppColors.error),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Notification Dispatch Confirmation & Direct Launchers
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1120),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alert Mail target: $email',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.sms_outlined, color: AppColors.success, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alert Mobile target: $phone',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '📱 Open alert directly on your connected device:',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 14),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          EmergencyDispatchService().openWhatsAppAlert(
                            roomId: roomId,
                            temperature: temperature,
                            fireAngle: fireAngle,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.sms_outlined, size: 14),
                        label: const Text('SMS / Msg', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          EmergencyDispatchService().openSmsAlert(
                            roomId: roomId,
                            temperature: temperature,
                            fireAngle: fireAngle,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: const BorderSide(color: Colors.amber),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.email_outlined, size: 14),
                        label: const Text('Mail App', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          EmergencyDispatchService().openMailAlert(
                            roomId: roomId,
                            temperature: temperature,
                            fireAngle: fireAngle,
                            riskScore: riskScore,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Question
          const Center(
            child: Text(
              'Please verify your home status:\nDid you inspect the area?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Choice 1: NO - Issue Cleared Out
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'NO, ISSUE IS CLEARED (Checked & Safe)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: onIssueCleared,
            ),
          ),
          const SizedBox(height: 8),

          // Choice 2: YES - Emergency Confirmed
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.warning_amber),
              label: const Text(
                'YES, ACTIVE EMERGENCY (Sound Alarm & SOS)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: onEmergencyConfirmed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        Text(
          val,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
