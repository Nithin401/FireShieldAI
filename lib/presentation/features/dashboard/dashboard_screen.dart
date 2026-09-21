import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/models/notification_model.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';
import 'package:fireshield_app/presentation/features/notifications/providers/notification_providers.dart';
import 'package:fireshield_app/presentation/features/dashboard/widgets/sensor_card.dart';
import 'package:fireshield_app/presentation/features/dashboard/widgets/directional_radar_card.dart';
import 'package:fireshield_app/presentation/features/dashboard/widgets/multi_sensor_gauges_card.dart';
import 'package:fireshield_app/presentation/features/dashboard/widgets/simulation_controls_card.dart';
import 'package:fireshield_app/presentation/features/dashboard/widgets/live_alerts_feed_card.dart';
import 'package:fireshield_app/presentation/features/dashboard/widgets/home_verification_dialog.dart';
import 'package:fireshield_app/core/services/emergency_dispatch_service.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _currentScenario = 'NORMAL';

  Future<void> _handleSimulation(String scenario) async {
    setState(() {
      _currentScenario = scenario;
    });

    await ref.read(deviceRepositoryProvider).simulateScenario(scenario, deviceId: 'dev_001');

    if (scenario == 'FIRE') {
      final alertId = 'alt_${DateTime.now().millisecondsSinceEpoch}';
      ref.read(notificationRepositoryProvider).addLocalAlert(
        NotificationModel(
          id: alertId,
          title: '🔥 CRITICAL FIRE ALERT: Kitchen',
          message: 'Abnormal heat (76.5°C) & flame IR detected! Risk: 99.4% | Angle: 45°',
          timestamp: DateTime.now(),
          isRead: false,
          severity: 'critical',
          deviceId: 'dev_001',
          roomId: 'Kitchen',
          fireState: 'FIRE',
          riskScore: 99.4,
          fireAngle: 45,
        ),
      );

      // Dispatch verification notification to User Messages & Mail
      await EmergencyDispatchService().sendEmergencyVerificationNotice(
        alertId: alertId,
        roomId: 'Kitchen',
        temperature: 76.5,
        fireAngle: 45,
        riskScore: 99.4,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('🔥 Fire & Abnormal Heat detected! Alerts sent to user Messages & Mail.'),
            duration: Duration(seconds: 3),
          ),
        );

        // Pop up the YES / NO Home Verification Dialog
        HomeVerificationDialog.show(
          context: context,
          roomId: 'Kitchen',
          temperature: 76.5,
          fireAngle: 45,
          riskScore: 99.4,
          email: EmergencyDispatchService().userEmail,
          phone: EmergencyDispatchService().userPhone,
          onIssueCleared: () => _handleIssueCleared('Kitchen'),
          onEmergencyConfirmed: () => _handleEmergencyConfirmed('Kitchen'),
        );
      }
    } else if (scenario == 'FALSE_ALARM') {
      ref.read(notificationRepositoryProvider).addLocalAlert(
        NotificationModel(
          id: 'alt_${DateTime.now().millisecondsSinceEpoch}',
          title: '⚠️ VOLATILE GAS WARNING: Kitchen',
          message: 'Elevated gas detected without thermal anomaly. Suppressed from false alarm.',
          timestamp: DateTime.now(),
          isRead: false,
          severity: 'warning',
          deviceId: 'dev_001',
          roomId: 'Kitchen',
          fireState: 'WARNING',
          riskScore: 36.0,
          fireAngle: 90,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.amber,
            content: Text('⚠️ False Alarm scenario simulated. Volatile gas elevated.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ System returned to NORMAL safe operational state.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    ref.invalidate(devicesStreamProvider);
    ref.invalidate(notificationsStreamProvider);
  }

  Future<void> _handleIssueCleared(String room) async {
    setState(() {
      _currentScenario = 'NORMAL';
    });

    // 1. Reset telemetry to SAFE in repository
    await ref.read(deviceRepositoryProvider).simulateScenario('NORMAL', deviceId: 'dev_001');

    // 2. Acknowledge and clear all unread alerts
    final alerts = ref.read(mockNotificationsProvider);
    for (final a in alerts) {
      if (!a.isRead) {
        await ref.read(mockNotificationsProvider.notifier).acknowledge(a.id);
      }
    }

    // 3. Dispatch All-Clear confirmation to Mail and Messages
    await EmergencyDispatchService().sendAllClearConfirmation(roomId: room);

    ref.invalidate(devicesStreamProvider);
    ref.invalidate(notificationsStreamProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('✅ Issue Cleared! Home verified safe by user. Safe mode restored.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleEmergencyConfirmed(String room) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('🚨 Active Emergency Confirmed! Alarms active and emergency dispatch alerted.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleAngleNudge(int angle) async {
    final devices = ref.read(devicesStreamProvider).value ?? [];
    if (devices.isEmpty) return;
    final primary = devices.first;
    final updated = primary.copyWith(fireAngle: angle);
    await ref.read(deviceRepositoryProvider).updateDevice(updated);
    ref.invalidate(devicesStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final notifications = ref.watch(mockNotificationsProvider);
    final unreadCriticalCount = notifications.where((n) => !n.isRead && n.severity == 'critical').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              '🛡️ FireShield AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success),
              ),
              child: const Text(
                'LIVE OPS',
                style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phonelink_ring_outlined),
            tooltip: 'Test Device Notification',
            onPressed: () {
              requestNotificationPermission();
              triggerSystemNotification(
                '🔔 FireShield AI Device Test',
                'Your device is connected and ready to receive real-time emergency fire alerts!',
                'critical',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.blue,
                  content: Text('🔔 Sent test alert to this device! Tap "Allow" if your browser prompts.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Telemetry',
            onPressed: () {
              ref.invalidate(devicesStreamProvider);
              ref.invalidate(notificationsStreamProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Telemetry & AI Engine Synchronized')),
              );
            },
          ),
          IconButton(
            icon: unreadCriticalCount > 0
                ? Badge.count(
                    count: unreadCriticalCount,
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.notifications_active),
                  )
                : const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: devicesAsync.when(
        data: (devices) {
          final primaryDevice = devices.firstWhere(
            (d) => d.id == 'dev_001',
            orElse: () => devices.isNotEmpty
                ? devices.first
                : DeviceModel(
                    id: 'dev_001',
                    name: 'Primary Node',
                    room: 'Kitchen',
                    latitude: 37.77,
                    longitude: -122.41,
                    firmwareVersion: 'v2.0',
                    isOnline: true,
                    batteryLevel: 95,
                    wifiSignalStrength: 90,
                    lastSync: DateTime.now(),
                  ),
          );

          bool hasFireAlert = devices.any((d) => d.fireState == 'FIRE' || d.fireState == 'HIGH_RISK');
          int offlineCount = devices.where((d) => !d.isOnline).length;

          Color statusColor = AppColors.success;
          String statusTitle = 'All Systems Nominal';
          String statusSubtitle = 'Hybrid AI Risk Engine active. Continuous multi-sensor scan in progress.';
          IconData statusIcon = Icons.verified_user;

          if (hasFireAlert) {
            statusColor = AppColors.error;
            statusTitle = 'CRITICAL FIRE DETECTED';
            statusSubtitle = 'Thermal & Flame anomaly active in ${primaryDevice.room}! Servo locked at ${primaryDevice.fireAngle}°.';
            statusIcon = Icons.local_fire_department;
          } else if (offlineCount > 0) {
            statusColor = AppColors.warning;
            statusTitle = 'System Warning';
            statusSubtitle = '$offlineCount device(s) offline. Check network gateway.';
            statusIcon = Icons.warning_amber_rounded;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. AI Threat Status Banner
                      InkWell(
                        onTap: () => context.push('/notifications'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [statusColor, statusColor.withValues(alpha: 0.75)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(statusIcon, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      statusTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      statusSubtitle,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Home Verification Card (Prompted on Abnormal Heat & Fire Detection)
                      if (hasFireAlert) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.error, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.25),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.mark_email_read, color: Color(0xFF38BDF8), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'HOME VERIFICATION REQUIRED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Alerts dispatched to your Messages & Mail',
                                          style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'VERIFY',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Abnormal temperature (${primaryDevice.ambientTemperature.toStringAsFixed(1)}°C) detected in ${primaryDevice.room}. Have you checked your home?',
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  // Button NO: Issue Cleared Out
                                  Expanded(
                                    flex: 6,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: const Text(
                                        'NO, ISSUE CLEARED',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _handleIssueCleared(primaryDevice.room),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Button YES: Active Fire
                                  Expanded(
                                    flex: 5,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error, width: 1.5),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.warning_amber, size: 18),
                                      label: const Text(
                                        'YES, ACTIVE FIRE',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _handleEmergencyConfirmed(primaryDevice.room),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 2. Event Simulation Injector Bar
                      SimulationControlsCard(
                        currentScenario: _currentScenario,
                        onSimulate: _handleSimulation,
                      ),
                      const SizedBox(height: 16),

                      // 3. Directional Radar & Multi-Sensor Telemetry (Responsive Row / Column)
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: DirectionalRadarCard(
                                angle: primaryDevice.fireAngle,
                                fireState: primaryDevice.fireState,
                                responseStatus: primaryDevice.responseStatus,
                                onAngleSelected: _handleAngleNudge,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: MultiSensorGaugesCard(
                                temperature: primaryDevice.ambientTemperature,
                                smoke: primaryDevice.smokeRaw,
                                gas: primaryDevice.gasRaw,
                                flameRaw: primaryDevice.flameRaw,
                                fireState: primaryDevice.fireState,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        DirectionalRadarCard(
                          angle: primaryDevice.fireAngle,
                          fireState: primaryDevice.fireState,
                          responseStatus: primaryDevice.responseStatus,
                          onAngleSelected: _handleAngleNudge,
                        ),
                        const SizedBox(height: 16),
                        MultiSensorGaugesCard(
                          temperature: primaryDevice.ambientTemperature,
                          smoke: primaryDevice.smokeRaw,
                          gas: primaryDevice.gasRaw,
                          flameRaw: primaryDevice.flameRaw,
                          fireState: primaryDevice.fireState,
                        ),
                      ],
                      const SizedBox(height: 20),

                      // 4. Active Detection Zones Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Detection Zones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/devices'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Manage Fleet ↗', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          Color cardColor = AppColors.success;
                          if (device.fireState == 'FIRE' || device.fireState == 'HIGH_RISK') {
                            cardColor = AppColors.error;
                          } else if (device.fireState == 'WARNING') {
                            cardColor = AppColors.warning;
                          } else if (!device.isOnline) {
                            cardColor = Colors.grey;
                          }

                          return SensorCard(
                            title: '${device.room} (${device.fireAngle}°)',
                            value: '${device.riskScore.toStringAsFixed(0)}% Risk',
                            unit: device.fireState,
                            icon: device.fireState == 'FIRE' ? Icons.local_fire_department : Icons.sensors,
                            color: cardColor,
                            onTap: () {
                              context.push('/devices/${device.id}');
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 5. Live Incidents & Alert Audit Feed
                      LiveAlertsFeedCard(
                        alerts: notifications,
                        onAcknowledge: (alertId) {
                          ref.read(mockNotificationsProvider.notifier).acknowledge(alertId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Incident acknowledged and logged in audit trail.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        onViewAll: () => context.push('/notifications'),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
