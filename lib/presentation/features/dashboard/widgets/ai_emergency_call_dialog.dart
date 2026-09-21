import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/core/services/emergency_dispatch_service.dart';

class AiEmergencyCallDialog extends StatefulWidget {
  final String roomId;
  final double temperature;
  final int fireAngle;
  final double riskScore;
  final String email;
  final String phone;
  final VoidCallback onIssueCleared;
  final VoidCallback onEmergencyConfirmed;

  const AiEmergencyCallDialog({
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
      builder: (ctx) => AiEmergencyCallDialog(
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
  State<AiEmergencyCallDialog> createState() => _AiEmergencyCallDialogState();
}

class _AiEmergencyCallDialogState extends State<AiEmergencyCallDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });

    // Start AI Emergency Speech Narration
    EmergencyDispatchService().triggerAiEmergencyCall(
      roomId: widget.roomId,
      temperature: widget.temperature,
      fireAngle: widget.fireAngle,
      riskScore: widget.riskScore,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer.cancel();
    EmergencyDispatchService().stopAiEmergencyCall();
    super.dispose();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.error, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Active Call Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI EMERGENCY VOICE CALL',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_seconds),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Caller Avatar with Pulsing Waves
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80 + (_pulseController.value * 16),
                      height: 80 + (_pulseController.value * 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.25 * (1 - _pulseController.value)),
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E293B),
                        border: Border.all(color: AppColors.error, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.record_voice_over,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // 3. Caller Identity
            const Text(
              'FireShield AI Safety Central',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Connected SOS Device: ${widget.phone}',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // 4. Live Speech / Telemetry Dispatch Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up, color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'AI Voice Telemetry Dispatch:',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.replay, color: Colors.white70, size: 16),
                        tooltip: 'Repeat Voice Alert',
                        onPressed: () {
                          EmergencyDispatchService().triggerAiEmergencyCall(
                            roomId: widget.roomId,
                            temperature: widget.temperature,
                            fireAngle: widget.fireAngle,
                            riskScore: widget.riskScore,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '⚠️ "Abnormal temperature (${widget.temperature.toStringAsFixed(1)}°C) detected in ${widget.roomId} at threat angle ${widget.fireAngle}°. AI risk is ${widget.riskScore.toStringAsFixed(0)}%.\nVerify home: NO (cleared) or YES (emergency)."',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Multi-Channel Quick Action Row (SOS Call, WhatsApp, SMS)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Dial SOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      EmergencyDispatchService().dialSosEmergencyCall();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.chat, size: 15),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      EmergencyDispatchService().openWhatsAppAlert(
                        roomId: widget.roomId,
                        temperature: widget.temperature,
                        fireAngle: widget.fireAngle,
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.sms, size: 15),
                    label: const Text('SMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      EmergencyDispatchService().openSmsAlert(
                        roomId: widget.roomId,
                        temperature: widget.temperature,
                        fireAngle: widget.fireAngle,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Primary Home Verification Action Buttons (YES / NO)
            const Text(
              'Did you inspect the area? Verify home status:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Choice 1: NO - Issue Cleared
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'NO, ISSUE IS CLEARED (Checked & Safe)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  EmergencyDispatchService().stopAiEmergencyCall();
                  widget.onIssueCleared();
                },
              ),
            ),
            const SizedBox(height: 8),

            // Choice 2: YES - Confirmed Fire Emergency
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.warning_amber, size: 20),
                label: const Text(
                  'YES, ACTIVE FIRE (Sound SOS Alarm)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  EmergencyDispatchService().stopAiEmergencyCall();
                  widget.onEmergencyConfirmed();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
