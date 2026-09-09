import 'package:flutter/material.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class DeviceListTile extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;

  const DeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: device.isOnline ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sensors,
            color: device.isOnline ? AppColors.success : Colors.grey,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Room: ${device.room}'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.thermostat, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text('${device.ambientTemperature.toStringAsFixed(1)}°C'),
                const SizedBox(width: 12),
                const Icon(Icons.wb_sunny, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text('IR: ${device.irTemperature.toStringAsFixed(1)}°C'),
                const SizedBox(width: 12),
                const Icon(Icons.water_drop, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text('${device.ambientHumidity.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  device.batteryLevel > 20 
                      ? Icons.battery_full 
                      : Icons.battery_alert,
                  size: 14,
                  color: device.batteryLevel > 20 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text('${device.batteryLevel}%'),
                const SizedBox(width: 12),
                Icon(
                  Icons.wifi,
                  size: 14,
                  color: device.isOnline ? AppColors.info : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(device.isOnline ? '${device.wifiSignalStrength}%' : 'Offline'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
