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
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFA030712), // 98% opaque dark slate - completely prevents background merging
      barrierLabel: 'AI Emergency Call',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => AiEmergencyCallDialog(
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
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
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
  EscalationPhase _phase = EscalationPhase.verifying;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });

    // Start autonomous 30s/2m escalation sequence with continuous loud AI voice & siren sound
    EmergencyDispatchService().startEscalationSequence(
      roomId: widget.roomId,
      temperature: widget.temperature,
      fireAngle: widget.fireAngle,
      riskScore: widget.riskScore,
      onTick: (phase, countdownSec) {
        if (mounted) {
          setState(() {
            _phase = phase;
            _countdown = countdownSec;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 640;

    final contentWidget = _buildCallContent(context, isMobile: isMobile);

    if (isMobile) {
      // Mobile: Full-screen dedicated call HUD with zero backdrop bleed-through
      return Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          child: contentWidget,
        ),
      );
    } else {
      // Desktop / Tablet: Centered modal card with clean solid backdrop
      return Dialog(
        backgroundColor: const Color(0xFF0F172A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.error, width: 2),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: contentWidget,
          ),
        ),
      );
    }
  }

  Widget _buildCallContent(BuildContext context, {required bool isMobile}) {
    return Column(
      children: [
        // 1. Top Call Status Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 0,
            vertical: isMobile ? 12 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              IconButton(
                icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white60, size: 20),
                tooltip: 'Minimize Call to Dashboard',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF1E293B), height: 16),

        // 2. Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 4,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // 2.1 Caller Avatar with Pulsing Waves
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 84 + (_pulseController.value * 22),
                          height: 84 + (_pulseController.value * 22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.22 * (1 - _pulseController.value)),
                          ),
                        ),
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E293B),
                            border: Border.all(color: AppColors.error, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.4),
                                blurRadius: 18,
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

                // 2.2 Caller Details
                const Text(
                  'FireShield AI Safety Central',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${widget.phone} | ${widget.email}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // 2.3 Live Autonomous Escalation Status Banner (30s Direct Call -> 2m Fire Safety Dept)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _phase == EscalationPhase.fireSafetyDispatched
                        ? const Color(0xFF7F1D1D).withValues(alpha: 0.6)
                        : _phase == EscalationPhase.directCallDispatched
                            ? const Color(0xFF831843).withValues(alpha: 0.5)
                            : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _phase == EscalationPhase.fireSafetyDispatched
                          ? Colors.redAccent
                          : _phase == EscalationPhase.directCallDispatched
                              ? Colors.amber
                              : const Color(0xFF334155),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Multi-Stage Visual Stepper
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStepIndicator(
                            step: '1',
                            label: 'Alarm (30s)',
                            isActive: _phase == EscalationPhase.verifying,
                            isPassed: _phase != EscalationPhase.verifying,
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white30),
                          _buildStepIndicator(
                            step: '2',
                            label: 'Direct Call',
                            isActive: _phase == EscalationPhase.directCallDispatched,
                            isPassed: _phase == EscalationPhase.fireSafetyDispatched,
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white30),
                          _buildStepIndicator(
                            step: '3',
                            label: 'Fire Dept (2m)',
                            isActive: _phase == EscalationPhase.fireSafetyDispatched,
                            isPassed: false,
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF334155), height: 16),
                      // Dynamic Phase Message & Countdown
                      Row(
                        children: [
                          Icon(
                            _phase == EscalationPhase.fireSafetyDispatched
                                ? Icons.local_fire_department
                                : _phase == EscalationPhase.directCallDispatched
                                    ? Icons.phone_forwarded
                                    : Icons.timer_outlined,
                            color: _phase == EscalationPhase.fireSafetyDispatched
                                ? Colors.redAccent
                                : _phase == EscalationPhase.directCallDispatched
                                    ? Colors.amber
                                    : const Color(0xFF38BDF8),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _phase == EscalationPhase.verifying
                                      ? 'AUTO-DIALING DIRECT CALL IN $_countdown SEC'
                                      : _phase == EscalationPhase.directCallDispatched
                                          ? 'DIRECT CALL ACTIVE! ESCALATING IN $_countdown SEC'
                                          : 'ESCALATED TO FIRE SAFETY AUTHORITIES (101)',
                                  style: TextStyle(
                                    color: _phase == EscalationPhase.fireSafetyDispatched
                                        ? Colors.redAccent
                                        : _phase == EscalationPhase.directCallDispatched
                                            ? Colors.amber
                                            : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _phase == EscalationPhase.verifying
                                      ? 'AI voice & siren sounding. If no one responds in 30s, call connects to ${widget.phone}.'
                                      : _phase == EscalationPhase.directCallDispatched
                                          ? 'Direct call & SMS active! If still unacknowledged at 2m, auto-escalates to Fire Safety.'
                                          : 'Alert message dispatched directly to Fire Safety Department without intimation. Tap Cancel below if safe.',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2.4 Critical Telemetry Highlight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E33),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricBadge('Zone', widget.roomId, Colors.white),
                      _buildDivider(),
                      _buildMetricBadge('Temp', '${widget.temperature.toStringAsFixed(1)}°C', AppColors.error),
                      _buildDivider(),
                      _buildMetricBadge('Bearing', '${widget.fireAngle}°', const Color(0xFF38BDF8)),
                      _buildDivider(),
                      _buildMetricBadge('Risk', '${widget.riskScore.toStringAsFixed(0)}%', AppColors.error),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2.4 Live Speech Narration Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
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
                            'AI Audio Broadcast Transmission:',
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
                            tooltip: 'Replay Speech',
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
                        '⚠️ "Critical abnormal heat (${widget.temperature.toStringAsFixed(1)}°C) detected in ${widget.roomId} at threat angle ${widget.fireAngle}°. Home verification required. Select NO if issue is cleared, or YES for emergency."',
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

                // 2.5 Quick Contact Actions (Direct Dial, WhatsApp, SMS)
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
                        icon: const Icon(Icons.phone_in_talk, size: 15),
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
                        icon: const Icon(Icons.chat_bubble_outline, size: 14),
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
                        icon: const Icon(Icons.sms_outlined, size: 14),
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
              ],
            ),
          ),
        ),

        // 3. Dedicated Verification Action Dock at Bottom (Clean, Distinct, Never Merging)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 18 : 8,
            vertical: 14,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Have you checked the room? Verify home status:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Button 1: NO - ISSUE CLEARED
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NO, ISSUE IS CLEARED',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Home checked & verified safe • Disarm alarm',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    await EmergencyDispatchService().cancelEscalation(roomId: widget.roomId);
                    widget.onIssueCleared();
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Button 2: YES - ACTIVE FIRE
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.warning_amber, size: 20),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'YES, ACTIVE FIRE EMERGENCY',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Confirm fire • Fast-Forward Direct Call & Fire Dept SOS',
                        style: TextStyle(fontSize: 10, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    final service = EmergencyDispatchService();
                    service.stopEscalation();
                    await service.executeDirectPhoneCall(widget.phone);
                    await service.executeDirectPhoneCall(service.fireSafetyPhone);
                    widget.onEmergencyConfirmed();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 22,
      color: const Color(0xFF1E293B),
    );
  }

  Widget _buildStepIndicator({
    required String step,
    required String label,
    required bool isActive,
    required bool isPassed,
  }) {
    final color = isPassed
        ? AppColors.success
        : isActive
            ? AppColors.error
            : const Color(0xFF64748B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: isPassed
              ? const Icon(Icons.check, size: 10, color: AppColors.success)
              : Text(
                  step,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
