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
import 'package:fireshield_app/presentation/features/dashboard/widgets/ai_emergency_call_dialog.dart';
import 'package:fireshield_app/core/services/emergency_dispatch_service.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _currentScenario = 'NORMAL';
  bool _hasDispatchedHardwareAlert = false;

  void _showContactSetupModal() {
    final service = EmergencyDispatchService();
    final emailController = TextEditingController(text: service.userEmail);
    final phoneController = TextEditingController(text: service.userPhone);
    final fireDeptController = TextEditingController(text: service.fireSafetyPhone);
    bool autoDispatch = service.autoDispatchEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phonelink_ring, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alert Recipient Settings',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Route real fire & abnormal heat alerts to your device',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Your Mobile Number (SMS & WhatsApp)',
                  hintText: 'e.g. +91 9876543210 or +1 2345678900',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.phone_android, color: Colors.green),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Your Emergency Alert Email',
                  hintText: 'e.g. yourname@gmail.com',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF38BDF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fireDeptController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Fire Dept SOS Number (2-Min Auto Escalation)',
                  hintText: 'e.g. 101 or 911',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.local_fire_department, color: Colors.redAccent),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: autoDispatch ? AppColors.error.withValues(alpha: 0.5) : const Color(0xFF334155),
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Instant Auto-Dispatch (Zero-Click)',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    autoDispatch
                        ? 'Active: 30s in-app verification -> direct call to contact -> 2m auto-escalation to Fire Safety Department'
                        : 'Manual: Prompts with verification dialog first',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  value: autoDispatch,
                  activeTrackColor: AppColors.error,
                  onChanged: (val) {
                    setModalState(() {
                      autoDispatch = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final email = emailController.text;
                        final phone = phoneController.text;
                        final fireDept = fireDeptController.text;
                        await service.updateContacts(
                          email: email,
                          phone: phone,
                          fireDeptPhone: fireDept,
                          autoDispatch: autoDispatch,
                        );
                        if (!mounted) return;
                        setState(() {});
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('✅ Alert contacts saved! Real alerts will route to your phone & mail.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Test SMS', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      service.openSmsAlert(
                        roomId: 'Kitchen',
                        temperature: 76.5,
                        fireAngle: 45,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

      final dispatchService = EmergencyDispatchService();
      if (dispatchService.autoDispatchEnabled) {
        // Immediate Autonomous Dispatch: Direct phone call + Direct SMS + Loudspeaker Siren
        await dispatchService.executeImmediateAutonomousDispatch(
          roomId: 'Kitchen',
          temperature: 76.5,
          fireAngle: 45,
          riskScore: 99.4,
        );
      } else {
        // Dispatch verification notification to User Messages & Mail
        await dispatchService.sendEmergencyVerificationNotice(
          alertId: alertId,
          roomId: 'Kitchen',
          temperature: 76.5,
          fireAngle: 45,
          riskScore: 99.4,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('🔥 Fire Anomaly detected! Immediate Autonomous Emergency Call & SMS active for ${dispatchService.userPhone}...'),
            duration: const Duration(seconds: 4),
          ),
        );

        // Automatically launch the interactive AI Emergency Call HUD
        AiEmergencyCallDialog.show(
          context: context,
          roomId: 'Kitchen',
          temperature: 76.5,
          fireAngle: 45,
          riskScore: 99.4,
          email: dispatchService.userEmail,
          phone: dispatchService.userPhone,
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

    // Stop ongoing speech and speak All-Clear confirmation
    EmergencyDispatchService().stopAiEmergencyCall();
    makeAiEmergencyVoiceCall('Home verified safe by user. Alarms disarmed, normal room temperature restored.');

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
    EmergencyDispatchService().stopAiEmergencyCall();
    EmergencyDispatchService().dialSosEmergencyCall();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('🚨 Active Emergency Confirmed! Dialing SOS Emergency Dispatch and sounding siren.'),
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

  void _triggerDeviceTest() {
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
  }

  void _syncTelemetry() {
    ref.invalidate(devicesStreamProvider);
    ref.invalidate(notificationsStreamProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Telemetry & AI Engine Synchronized')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Automated listener: If live hardware detects critical fire, trigger immediate autonomous dispatch
    ref.listen<AsyncValue<List<DeviceModel>>>(devicesStreamProvider, (previous, next) {
      final devices = next.value ?? [];
      final criticalDevice = devices.cast<DeviceModel?>().firstWhere(
        (d) => d != null && (d.fireState == 'FIRE' || d.riskScore >= 80.0),
        orElse: () => null,
      );

      if (criticalDevice != null && !_hasDispatchedHardwareAlert) {
        _hasDispatchedHardwareAlert = true;
        final service = EmergencyDispatchService();
        if (service.autoDispatchEnabled) {
          service.executeImmediateAutonomousDispatch(
            roomId: criticalDevice.room,
            temperature: criticalDevice.ambientTemperature,
            fireAngle: criticalDevice.fireAngle,
            riskScore: criticalDevice.riskScore,
          );
        }
      } else if (criticalDevice == null) {
        _hasDispatchedHardwareAlert = false;
      }
    });

    final devicesAsync = ref.watch(devicesStreamProvider);
    final notifications = ref.watch(mockNotificationsProvider);
    final unreadCriticalCount = notifications.where((n) => !n.isRead && n.severity == 'critical').length;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileScreen = screenWidth < 640;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🛡️ FireShield AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(width: 8),
            if (isMobileScreen)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              )
            else
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
        actions: isMobileScreen
            ? [
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'contacts') _showContactSetupModal();
                    if (val == 'test') _triggerDeviceTest();
                    if (val == 'sync') _syncTelemetry();
                    if (val == 'settings') context.push('/settings');
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'contacts',
                      child: Row(
                        children: [
                          Icon(Icons.phone_in_talk_rounded, color: Color(0xFF38BDF8), size: 18),
                          SizedBox(width: 10),
                          Text('Alert Contacts & Auto-Dispatch', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'test',
                      child: Row(
                        children: [
                          Icon(Icons.phonelink_ring_outlined, color: Colors.amber, size: 18),
                          SizedBox(width: 10),
                          Text('Test Device Alert', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sync',
                      child: Row(
                        children: [
                          Icon(Icons.sync, color: AppColors.success, size: 18),
                          SizedBox(width: 10),
                          Text('Sync Telemetry', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 8),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: Colors.white70, size: 18),
                          SizedBox(width: 10),
                          Text('Account Settings', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.contact_phone_outlined),
                  tooltip: 'Configure Alert Contacts (Mobile & Mail)',
                  onPressed: _showContactSetupModal,
                ),
                IconButton(
                  icon: const Icon(Icons.phonelink_ring_outlined),
                  tooltip: 'Test Device Notification',
                  onPressed: _triggerDeviceTest,
                ),
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync Telemetry',
                  onPressed: _syncTelemetry,
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
                      // 1. Sleek Emergency Dispatch & Contacts Bar
                      InkWell(
                        onTap: _showContactSetupModal,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF131D31), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: EmergencyDispatchService().autoDispatchEnabled
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.5)
                                  : const Color(0xFF334155),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (EmergencyDispatchService().isCustomContactConfigured
                                          ? const Color(0xFF0284C7)
                                          : Colors.amber)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  EmergencyDispatchService().isCustomContactConfigured
                                      ? Icons.phone_in_talk_rounded
                                      : Icons.contact_phone_outlined,
                                  color: EmergencyDispatchService().isCustomContactConfigured
                                      ? const Color(0xFF38BDF8)
                                      : Colors.amber,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          EmergencyDispatchService().isCustomContactConfigured
                                              ? 'Active Auto-Dispatch'
                                              : 'Setup Emergency Contacts',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '30s / 2m SOS',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      EmergencyDispatchService().isCustomContactConfigured
                                          ? '${EmergencyDispatchService().userPhone} • Fire Dept: ${EmergencyDispatchService().fireSafetyPhone}'
                                          : 'Tap to configure mobile & fire department numbers',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 1.1 AI Threat Status Banner
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

                      // 1.2 Active Emergency Banner (Compact & Non-Clashing with Call HUD)
                      if (hasFireAlert) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1524),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.error, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.25),
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
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.phonelink_ring, color: Colors.redAccent, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ACTIVE EMERGENCY: VERIFY HOME',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${primaryDevice.room} • ${primaryDevice.ambientTemperature.toStringAsFixed(1)}°C • AI Call Active',
                                          style: const TextStyle(
                                            color: Color(0xFFF87171),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.record_voice_over, size: 14),
                                    label: const Text('Open Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      AiEmergencyCallDialog.show(
                                        context: context,
                                        roomId: primaryDevice.room,
                                        temperature: primaryDevice.ambientTemperature,
                                        fireAngle: primaryDevice.fireAngle,
                                        riskScore: primaryDevice.riskScore,
                                        email: EmergencyDispatchService().userEmail,
                                        phone: EmergencyDispatchService().userPhone,
                                        onIssueCleared: () => _handleIssueCleared(primaryDevice.room),
                                        onEmergencyConfirmed: () => _handleEmergencyConfirmed(primaryDevice.room),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: const Text(
                                        'NO, ISSUE CLEARED',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _handleIssueCleared(primaryDevice.room),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 5,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.warning_amber, size: 16),
                                      label: const Text(
                                        'YES, ACTIVE FIRE',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
