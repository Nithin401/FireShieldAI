import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';
import 'package:fireshield_app/presentation/common/widgets/sensor_line_chart.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class DeviceDetailsScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailsScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return devicesAsync.when(
      data: (devices) {
        final device = devices.firstWhere(
          (d) => d.id == deviceId,
          orElse: () => throw Exception('Device not found'),
        );

        // Mock data points for charts
        final temperatureData = [
          const FlSpot(0, 21.0),
          const FlSpot(2, 21.5),
          const FlSpot(4, 22.1),
          const FlSpot(6, 22.8),
          const FlSpot(8, 22.5),
          const FlSpot(10, 23.0),
        ];
        
        final coData = [
          const FlSpot(0, 0.5),
          const FlSpot(2, 0.8),
          const FlSpot(4, 1.2),
          const FlSpot(6, 1.0),
          const FlSpot(8, 0.9),
          const FlSpot(10, 1.1),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(device.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Navigate to Edit Device
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // TODO: Delete Device logic
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Device ID', device.id),
                _buildDetailRow('Room', device.room),
                _buildDetailRow('Firmware', device.firmwareVersion),
                _buildDetailRow('Status', device.isOnline ? 'Online' : 'Offline'),
                _buildDetailRow('Battery', '${device.batteryLevel}%'),
                _buildDetailRow('WiFi Signal', '${device.wifiSignalStrength}%'),
                
                const SizedBox(height: 32),
                Text(
                  'Historical Data',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SensorLineChart(
                  dataPoints: temperatureData,
                  lineColor: AppColors.warning,
                  title: 'Temperature (°C)',
                  yAxisLabel: '°C',
                ),
                const SizedBox(height: 16),
                SensorLineChart(
                  dataPoints: coData,
                  lineColor: AppColors.primary,
                  title: 'Carbon Monoxide (ppm)',
                  yAxisLabel: 'ppm',
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
