import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class MultiSensorGaugesCard extends StatelessWidget {
  final double temperature;
  final int smoke;
  final int gas;
  final int flameRaw;
  final String fireState;

  const MultiSensorGaugesCard({
    super.key,
    required this.temperature,
    required this.smoke,
    required this.gas,
    required this.flameRaw,
    required this.fireState,
  });

  @override
  Widget build(BuildContext context) {
    // Temperature thresholds: <40 safe, 40-55 warning, >55 danger
    final tempPercent = (temperature / 100.0).clamp(0.0, 1.0);
    final tempColor = temperature > 55
        ? AppColors.error
        : (temperature > 40 ? AppColors.warning : AppColors.success);

    // Smoke thresholds: <300 safe, 300-600 warning, >600 danger
    final smokePercent = (smoke / 1000.0).clamp(0.0, 1.0);
    final smokeColor = smoke > 600
        ? AppColors.error
        : (smoke > 300 ? AppColors.warning : AppColors.success);

    // Gas thresholds: <300 safe, 300-500 warning, >500 danger
    final gasPercent = (gas / 1000.0).clamp(0.0, 1.0);
    final gasColor = gas > 500
        ? AppColors.error
        : (gas > 300 ? AppColors.warning : AppColors.success);

    // Flame sensor: lower raw means higher flame intensity. <300 FIRE, 300-700 WARNING, >700 SAFE
    final flameIntensity = (1.0 - (flameRaw / 1023.0)).clamp(0.0, 1.0);
    final flameColor = flameRaw < 300
        ? AppColors.error
        : (flameRaw < 700 ? AppColors.warning : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Multi-Sensor Fleet Telemetry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sensor 1: Temperature
          _buildGaugeItem(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: '${temperature.toStringAsFixed(1)} °C',
            percentage: tempPercent,
            color: tempColor,
            thresholdText: 'Normal (<45°C) | Alarm (>55°C)',
          ),
          const SizedBox(height: 14),

          // Sensor 2: Smoke Level
          _buildGaugeItem(
            icon: Icons.cloud,
            label: 'Smoke Density',
            value: '$smoke ppm',
            percentage: smokePercent,
            color: smokeColor,
            thresholdText: 'Safe (<300) | Dense Smoke (>600)',
          ),
          const SizedBox(height: 14),

          // Sensor 3: Gas Concentration
          _buildGaugeItem(
            icon: Icons.propane_tank,
            label: 'Gas Level (MQ-2)',
            value: '$gas ppm',
            percentage: gasPercent,
            color: gasColor,
            thresholdText: 'Safe (<300) | Combustible (>500)',
          ),
          const SizedBox(height: 14),

          // Sensor 4: Flame IR Sensor
          _buildGaugeItem(
            icon: Icons.local_fire_department,
            label: 'Flame IR Intensity',
            value: flameRaw < 300 ? 'ACTIVE FLAME ($flameRaw)' : 'Clear ($flameRaw)',
            percentage: flameIntensity,
            color: flameColor,
            thresholdText: 'IR Detection Range: 760nm - 1100nm',
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeItem({
    required IconData icon,
    required String label,
    required String value,
    required double percentage,
    required Color color,
    required String thresholdText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            width: double.infinity,
            color: const Color(0xFF334155),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          thresholdText,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
