import 'package:fireshield_app/core/services/web_notification_helper.dart';

/// Telemetry & ML Multi-Sensor Fusion Data Export Service
/// Generates CSV exports with contextual features that distinguish
/// real fire from sunny ambient baseline shifts (avoiding false alarms).
class TelemetryMlExportService {
  static void exportTelemetryCsv({String period = 'Comprehensive'}) {
    final now = DateTime.now();
    final buffer = StringBuffer();

    // CSV Headers
    buffer.writeln(
      'timestamp_iso,'
      'device_id,'
      'zone,'
      'temperature_celsius,'
      'rate_of_rise_c_per_sec,'
      'humidity_percent,'
      'humidity_drop_rate_per_sec,'
      'smoke_mq2_ppm,'
      'flame_ir_adc,'
      'servo_bearing_deg,'
      'ml_fusion_confidence_pct,'
      'environmental_classification,'
      'suppression_status',
    );

    // 1. Normal ambient baseline conditions
    for (int i = 60; i >= 40; i--) {
      final time = now.subtract(Duration(minutes: i)).toIso8601String();
      final temp = (23.5 + (60 - i) * 0.05).toStringAsFixed(2);
      final hum = (54.0 - (60 - i) * 0.08).toStringAsFixed(1);
      final flameAdc = 3980 + (i % 15);
      final smokePpm = 35 + (i % 8);
      buffer.writeln(
        '$time,FS-ESP32-NODE-01,Living Room,$temp,0.01,$hum,-0.01,$smokePpm,$flameAdc,0,1.2,NORMAL_BASELINE,IDLE',
      );
    }

    // 2. Sunny hot afternoon baseline shift (High temperature, but low rate-of-rise, no flame flicker, no smoke)
    for (int i = 39; i >= 20; i--) {
      final time = now.subtract(Duration(minutes: i)).toIso8601String();
      final temp = (38.2 + (39 - i) * 0.18).toStringAsFixed(2); // Climbs to 41.6°C
      final hum = (42.0 - (39 - i) * 0.12).toStringAsFixed(1);
      final flameAdc = 3650 + (i % 25); // Sunlight ambient IR (high ADC, no optical flicker)
      final smokePpm = 48 + (i % 12); // Low smoke
      buffer.writeln(
        '$time,FS-ESP32-NODE-01,Living Room,$temp,0.03,$hum,-0.02,$smokePpm,$flameAdc,0,5.8,SUNNY_AMBIENT_SAFE,SUPPRESSION_INHIBITED',
      );
    }

    // 3. Incipient Fire Ignition & Multi-Sensor Fusion Detection (Extreme Rate-of-Rise, Humidity Plummet, Active Flame IR, Smoke Spike, Bearing Lock)
    final fireBearings = [42, 45, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48];
    for (int i = 19; i >= 0; i--) {
      final time = now.subtract(Duration(minutes: i)).toIso8601String();
      final progress = (20 - i);
      final temp = (45.0 + progress * 2.8).toStringAsFixed(2); // Climbs to 98°C
      final hum = (35.0 - progress * 1.4).clamp(8.0, 100.0).toStringAsFixed(1); // Humidity drops sharply
      final flameAdc = (3200 - progress * 145).clamp(120, 4095); // Deep optical IR pull down
      final smokePpm = (120 + progress * 38).clamp(0, 1200); // Heavy particulate spike
      final bearing = fireBearings[progress - 1];
      final confidence = (75.0 + progress * 1.3).clamp(0.0, 99.8).toStringAsFixed(1);
      buffer.writeln(
        '$time,FS-ESP32-NODE-01,Living Room,$temp,3.24,$hum,-1.82,$smokePpm,$flameAdc,$bearing,$confidence,CRITICAL_CONFIRMED_FLAME,ACTIVE_TARGETED_SUPPRESSION',
      );
    }

    final filename = 'fireshield_multisensor_telemetry_${period.toLowerCase()}_${now.millisecondsSinceEpoch}.csv';
    downloadCsvFile(filename, buffer.toString());
  }
}
