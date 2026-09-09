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
          orElse: () => devices.isNotEmpty ? devices.first : throw Exception('Device not found'),
        );

        final flameChartData = [
          FlSpot(0, (device.flameRaw).toDouble()),
          FlSpot(2, (device.flameRaw + 10).toDouble()),
          FlSpot(4, (device.flameRaw - 15).toDouble()),
          FlSpot(6, (device.flameRaw + 5).toDouble()),
          FlSpot(8, (device.flameRaw - 20).toDouble()),
          FlSpot(10, (device.flameRaw).toDouble()),
        ];
        
        final riskChartData = [
          const FlSpot(0, 5.0),
          const FlSpot(2, 10.0),
          const FlSpot(4, 12.0),
          FlSpot(6, device.riskScore),
          FlSpot(8, device.riskScore),
          FlSpot(10, device.riskScore),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(device.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Device ID', device.id),
                _buildDetailRow('Room / Zone', device.room),
                _buildDetailRow('AI Risk Score', '${device.riskScore.toStringAsFixed(1)}% (${device.fireState})'),
                _buildDetailRow('Flame Raw (A0)', '${device.flameRaw}'),
                _buildDetailRow('Fire Angle', '${device.fireAngle}°'),
                _buildDetailRow('ESP2 Response', device.responseStatus),
                _buildDetailRow('Status', device.isOnline ? 'Online' : 'Offline'),
                _buildDetailRow('Battery', '${device.batteryLevel}%'),
                _buildDetailRow('WiFi Signal', '${device.wifiSignalStrength}%'),
                _buildDetailRow('Firmware', device.firmwareVersion),
                
                const SizedBox(height: 32),
                Text(
                  'Real-Time Telemetry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SensorLineChart(
                  dataPoints: flameChartData,
                  lineColor: AppColors.primary,
                  title: 'Flame Analog Signal (Raw A0)',
                  yAxisLabel: 'Raw',
                ),
                const SizedBox(height: 16),
                SensorLineChart(
                  dataPoints: riskChartData,
                  lineColor: device.riskScore > 50 ? AppColors.error : AppColors.success,
                  title: 'AI Risk Engine Score (0-100%)',
                  yAxisLabel: '%',
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
            width: 130,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
