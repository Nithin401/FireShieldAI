import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fireshield_app/core/services/flask_api_service.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class RoomAdaptiveRiskCard extends StatefulWidget {
  const RoomAdaptiveRiskCard({super.key});

  @override
  State<RoomAdaptiveRiskCard> createState() => _RoomAdaptiveRiskCardState();
}

class _RoomAdaptiveRiskCardState extends State<RoomAdaptiveRiskCard> {
  Timer? _pollTimer;
  Map<String, dynamic>? _riskData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRisk();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _fetchRisk());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRisk() async {
    final res = await FlaskApiService().getCurrentRisk();
    if (mounted && res != null) {
      setState(() {
        _riskData = res;
        _isLoading = false;
      });
    }
  }

  void _showNotificationSetupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _NotificationSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _riskData == null) {
      return const SizedBox.shrink();
    }

    final riskState = _riskData?['risk_state'] ?? 'NORMAL';
    final severity = _riskData?['severity'] ?? 'NORMAL';
    final reason = _riskData?['reason'] ?? 'Normal operation within room baseline';
    final metrics = _riskData?['metrics'] as Map<String, dynamic>? ?? {};

    final tempRate = metrics['temp_rate_c_min'] as num?;
    final tempDev = metrics['temp_deviation'] as num?;

    Color cardBorder;
    Color cardBg;
    IconData stateIcon;
    String title;

    if (riskState == 'HARDWARE_FIRE_ALERT') {
      cardBorder = AppColors.error;
      cardBg = const Color(0xFF2D1217);
      stateIcon = Icons.local_fire_department;
      title = '🔥 HARDWARE FIRE ALARM (field6 = 1)';
    } else if (riskState == 'EARLY_WARNING') {
      cardBorder = Colors.orangeAccent;
      cardBg = const Color(0xFF2B1D0E);
      stateIcon = Icons.warning_amber_rounded;
      title = '⚠️ EARLY WARNING: ELEVATED FIRE RISK';
    } else if (riskState == 'BASELINE_ANOMALY') {
      cardBorder = const Color(0xFF38BDF8);
      cardBg = const Color(0xFF0B213A);
      stateIcon = Icons.show_chart_rounded;
      title = 'ℹ️ ENVIRONMENTAL BASELINE ANOMALY';
    } else if (riskState == 'SENSOR_OR_DATA_FAULT') {
      cardBorder = Colors.amber;
      cardBg = const Color(0xFF261D0C);
      stateIcon = Icons.build_rounded;
      title = '⚠️ SENSOR OR TELEMETRY FAULT';
    } else {
      cardBorder = AppColors.success.withValues(alpha: 0.6);
      cardBg = const Color(0xFF0D251D);
      stateIcon = Icons.verified_user_rounded;
      title = '🛡️ ROOM-ADAPTIVE STATUS: NORMAL';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardBorder.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stateIcon, color: cardBorder, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: cardBorder,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: _showNotificationSetupModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Push Alerts',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (tempRate != null) ...[
                _buildMetricPill(
                  label: 'Rise Rate',
                  value: '${tempRate > 0 ? "+" : ""}${tempRate.toStringAsFixed(2)} °C/min',
                  color: tempRate >= 1.5 ? Colors.orangeAccent : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
              ],
              if (tempDev != null) ...[
                _buildMetricPill(
                  label: 'Baseline Dev',
                  value: '${tempDev > 0 ? "+" : ""}${tempDev.toStringAsFixed(1)} °C',
                  color: tempDev.abs() >= 2.5 ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
              ],
              _buildMetricPill(
                label: 'Severity',
                value: severity.toString().toUpperCase(),
                color: cardBorder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _NotificationSetupSheet extends StatefulWidget {
  const _NotificationSetupSheet();

  @override
  State<_NotificationSetupSheet> createState() => _NotificationSetupSheetState();
}

class _NotificationSetupSheetState extends State<_NotificationSetupSheet> {
  Map<String, dynamic>? _status;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final status = await FlaskApiService().getNotificationStatus();
    final events = await FlaskApiService().getEvents(limit: 5);
    if (mounted) {
      setState(() {
        _status = status;
        _events = events;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerTestAlert(String channel) async {
    setState(() => _testMessage = 'Sending $channel test notification...');
    final ok = await FlaskApiService().sendTestNotification(channel);
    if (mounted) {
      setState(() {
        _testMessage = ok ? '✅ $channel test alert sent!' : '❌ Failed to send $channel test alert.';
      });
      _loadData();
    }
  }

  Future<void> _openNtfyTopic(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ntfy topic link copied to clipboard:\n$url'),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final ntfyTopic = _status?['channels']?['ntfy']?['topic'] ?? 'fireshield_alerts_3534677';
    final ntfyUrl = _status?['channels']?['ntfy']?['public_url'] ?? 'https://ntfy.sh/$ntfyTopic';

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔔 Background Alert Setup',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'FireShield AI delivers real-time hazard alerts to your phone without Firebase SDKs.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Card 1: ntfy Mobile Alerts
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_android, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '1. Mobile Push Alerts via ntfy (Android / iOS)',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Install the official ntfy app from Google Play or Apple App Store and subscribe to your private topic:\nTopic: $ntfyTopic',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                        label: const Text('Copy Topic Link', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () => _openNtfyTopic(ntfyUrl),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Send Test Alert', style: TextStyle(fontSize: 12)),
                        onPressed: () => _triggerTestAlert('ntfy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_testMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_testMessage!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(height: 14),
            ],

            // Card 2: Recent Persistent Event Outbox Log
            const Text(
              'Recent Dispatched Hazard Events (SQLite Outbox):',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_events.isEmpty)
              const Text('No hazard events recorded yet. System normal.', style: TextStyle(color: Colors.white54, fontSize: 12))
            else
              ..._events.map((ev) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D31),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      ev['event_type'] ?? 'EVENT',
                      style: TextStyle(
                        color: (ev['event_type'] ?? '').contains('FIRE') ? AppColors.error : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ev['reason'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ev['timestamp'] != null ? ev['timestamp'].toString().substring(11, 16) : '',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}
