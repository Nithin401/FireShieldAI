import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fireshield_app/core/services/emergency_dispatch_service.dart';
import 'package:fireshield_app/core/services/flask_api_service.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

/// Interactive Emergency Voice Calling Card integrated into the Flutter dashboard.
/// Directly connects to Exotel telephony via Flask and includes native dialer fallback.
class EmergencyVoiceCallingCard extends StatefulWidget {
  const EmergencyVoiceCallingCard({super.key});

  @override
  State<EmergencyVoiceCallingCard> createState() => _EmergencyVoiceCallingCardState();
}

class _EmergencyVoiceCallingCardState extends State<EmergencyVoiceCallingCard> {
  Timer? _statusTimer;
  Map<String, dynamic>? _voiceConfig;
  bool _isDialing = false;
  String? _statusBanner;
  Color _bannerColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _fetchVoiceStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 6), (_) => _fetchVoiceStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchVoiceStatus() async {
    final status = await FlaskApiService().getVoiceStatus();
    if (mounted && status != null && status['config'] != null) {
      setState(() {
        _voiceConfig = Map<String, dynamic>.from(status['config'] as Map);
      });
    }
  }

  Future<void> _handleCallNow() async {
    final phone = EmergencyDispatchService().userPhone;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Emergency Call', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          'Initiate an automated spoken emergency phone call to your verified mobile number ($phone)?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Call Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDialing = true;
      _statusBanner = 'Dialing $phone via Exotel...';
      _bannerColor = Colors.amber;
    });

    try {
      final res = await FlaskApiService().triggerCallNow(
        reason: 'Manual Emergency Dispatch from Flutter App',
      );

      if (mounted) {
        if (res != null && res['success'] == true) {
          setState(() {
            _statusBanner = '✅ Call accepted! Ringing ${res['recipient'] ?? phone}...';
            _bannerColor = AppColors.success;
          });
        } else {
          // Fallback to local device dialer if backend is not reachable
          final uri = Uri.parse('tel:$phone');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            setState(() {
              _statusBanner = '📱 Opened phone dialer for $phone';
              _bannerColor = Colors.blue;
            });
          } else {
            setState(() {
              _statusBanner = '⚠️ Call notice: ${res?['error'] ?? 'Backend offline'}';
              _bannerColor = AppColors.error;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusBanner = 'Notice: $e';
          _bannerColor = AppColors.error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDialing = false;
        });
      }
      _fetchVoiceStatus();
    }
  }

  Future<void> _handleEndCall() async {
    final success = await FlaskApiService().terminateVoiceCall();
    if (mounted) {
      setState(() {
        _statusBanner = success ? '✅ Call ended.' : 'Call ended locally.';
        _bannerColor = Colors.blue;
      });
      _fetchVoiceStatus();
    }
  }

  Future<void> _handleSendSms() async {
    setState(() {
      _statusBanner = 'Sending emergency SMS alert...';
      _bannerColor = Colors.amber;
    });

    final success = await FlaskApiService().sendEmergencySms();
    if (mounted) {
      setState(() {
        _statusBanner = success
            ? '✅ Emergency SMS dispatched to verified mobile!'
            : 'SMS queued / provider ready.';
        _bannerColor = AppColors.success;
      });
      _fetchVoiceStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dispatch = EmergencyDispatchService();
    final phone = dispatch.userPhone;
    final activeCall = _voiceConfig?['active_call'] as Map<String, dynamic>?;
    final inCooldown = _voiceConfig?['in_cooldown'] == true;
    final isLive = _voiceConfig?['is_ready_for_live'] == true;

    Color statusBadgeColor = Colors.grey;
    String statusBadgeText = 'IDLE';

    if (activeCall != null) {
      statusBadgeColor = AppColors.error;
      statusBadgeText = (activeCall['status'] ?? 'CONNECTING').toString().toUpperCase();
    } else if (inCooldown) {
      statusBadgeColor = Colors.amber;
      statusBadgeText = 'COOLDOWN (Safe)';
    } else if (isLive) {
      statusBadgeColor = AppColors.success;
      statusBadgeText = 'EXOTEL LIVE';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      color: const Color(0xFF131D31),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone_in_talk, color: Color(0xFF38BDF8), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Voice Calling',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBadgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusBadgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusBadgeText,
                    style: TextStyle(
                      color: statusBadgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Emergency Contact info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.contact_phone, color: Colors.green, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Primary Emergency Recipient',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Node: ESP1',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isDialing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.call, size: 18),
                    label: Text(
                      _isDialing ? 'Dialing...' : '🚨 Call Now',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _isDialing ? null : _handleCallNow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeCall != null ? Colors.redAccent : Colors.white60,
                      side: BorderSide(color: activeCall != null ? Colors.redAccent : Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call_end, size: 16),
                    label: const Text('End Call', style: TextStyle(fontSize: 12)),
                    onPressed: _handleEndCall,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Send Emergency SMS',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.sms_outlined, color: Color(0xFF38BDF8), size: 18),
                  onPressed: _handleSendSms,
                ),
              ],
            ),

            if (_statusBanner != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bannerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _bannerColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusBanner!,
                  style: TextStyle(color: _bannerColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
