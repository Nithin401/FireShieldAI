import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';
import 'package:fireshield_app/presentation/features/dashboard/widgets/sensor_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FireShield AI Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              ref.invalidate(devicesStreamProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing live telemetry & AI Risk Scores...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
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
          bool hasFireAlert = devices.any((d) => d.fireState == 'FIRE' || d.fireState == 'HIGH_RISK');
          int offlineCount = devices.where((d) => !d.isOnline).length;

          Color statusColor = AppColors.success;
          String statusTitle = 'System Secure';
          String statusSubtitle = 'All zones normal. AI Risk Engine monitoring active.';
          IconData statusIcon = Icons.check_circle_outline;

          if (hasFireAlert) {
            statusColor = AppColors.error;
            statusTitle = 'CRITICAL FIRE ALERT';
            statusSubtitle = 'Thermal abnormality or active fire detected! Check details immediately.';
            statusIcon = Icons.local_fire_department;
          } else if (offlineCount > 0) {
            statusColor = AppColors.warning;
            statusTitle = 'System Warning';
            statusSubtitle = '$offlineCount device(s) offline. Please check connections.';
            statusIcon = Icons.warning_amber_rounded;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real AI Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              statusIcon,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              statusTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Active Devices & AI Risk Cards
                  Text(
                    'Active Detection Zones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
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
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
