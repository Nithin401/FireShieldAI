import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class MultiSensorGaugesCard extends StatelessWidget {
  final double temperature;
  final double humidity;
  final double pressure;
  final int gas;
  final double gasVoltage;
  final int flameRaw;
  final double flameVoltage;
  final String fireState;

  const MultiSensorGaugesCard({
    super.key,
    required this.temperature,
    this.humidity = 50.0,
    this.pressure = 1013.25,
    required this.gas,
    this.gasVoltage = 0.35,
    required this.flameRaw,
    this.flameVoltage = 3.0,
    required this.fireState,
    int? smoke, // Optional legacy alias
  });

  @override
  Widget build(BuildContext context) {
    // Temperature: <35 safe, 35-50 warning, >50 danger
    final tempPercent = (temperature / 80.0).clamp(0.0, 1.0);
    final tempColor = temperature > 50
        ? AppColors.error
        : (temperature > 35 ? AppColors.warning : AppColors.success);

    // Humidity: 30-70 normal, <30 dry, >70 damp
    final humPercent = (humidity / 100.0).clamp(0.0, 1.0);

    // Gas Level (ADS1115 A1: 0 to 32767 raw)
    // Prototype threshold: <12000 safe, 12000-18000 warning, >18000 high combustion
    final gasPercent = (gas / 30000.0).clamp(0.0, 1.0);
    final gasColor = gas > 18000
        ? AppColors.error
        : (gas > 12000 ? AppColors.warning : AppColors.success);

    // Flame IR Sensor (ADS1115 A0: 0 to 32767 raw, lower value = higher IR emission)
    // <4000 critical flame, <8000 fire, >12000 clear ambient
    final flameIntensity = (1.0 - (flameRaw / 25000.0)).clamp(0.0, 1.0);
    final flameColor = flameRaw < 4000
        ? AppColors.error
        : (flameRaw < 8000 ? AppColors.error : (flameRaw < 12000 ? AppColors.warning : AppColors.success));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Multi-Sensor Live Telemetry (ESP1)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  'ADS1115 16-Bit',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sensor 1: Temperature (BME280)
          _buildGaugeItem(
            icon: Icons.thermostat,
            label: 'Ambient Temperature',
            value: '${temperature.toStringAsFixed(1)} °C',
            percentage: tempPercent,
            color: tempColor,
            thresholdText: 'Normal (<35°C) | Warning (>35°C) | Alarm (>50°C)',
          ),
          const SizedBox(height: 14),

          // Sensor 2: Relative Humidity (BME280)
          _buildGaugeItem(
            icon: Icons.water_drop,
            label: 'Relative Humidity',
            value: '${humidity.toStringAsFixed(1)} %',
            percentage: humPercent,
            color: const Color(0xFF38BDF8),
            thresholdText: 'Ambient moisture | Barometric: ${pressure.toStringAsFixed(1)} hPa',
          ),
          const SizedBox(height: 14),

          // Sensor 3: Gas & Smoke (MQ-2 on ADS1115 A1)
          _buildGaugeItem(
            icon: Icons.propane_tank,
            label: 'Combustion Gas (MQ-2 AO)',
            value: '$gas (${gasVoltage.toStringAsFixed(2)} V)',
            percentage: gasPercent,
            color: gasColor,
            thresholdText: 'Baseline (<12k) | Pre-Fire (>18k ADC)',
          ),
          const SizedBox(height: 14),

          // Sensor 4: Optical Infrared Flame (KY-026 on ADS1115 A0)
          _buildGaugeItem(
            icon: Icons.local_fire_department,
            label: 'Optical Flame IR (KY-026 AO)',
            value: flameRaw < 8000 ? 'ACTIVE FLAME ($flameRaw / ${flameVoltage.toStringAsFixed(2)}V)' : 'Clear ($flameRaw / ${flameVoltage.toStringAsFixed(2)}V)',
            percentage: flameIntensity,
            color: flameColor,
            thresholdText: 'IR Band: 760–1100 nm | Threshold: <8,000 ADC',
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
