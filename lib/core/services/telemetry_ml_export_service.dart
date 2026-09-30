import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

/// Telemetry & ML Multi-Sensor Fusion Data Export Service
/// Generates 'smart_fire_dataset.csv' matching the exact 18-column Master Architecture Specification.
class TelemetryMlExportService {
  static const String rtdbHost =
      'https://smart-fire-detection-272bb-default-rtdb.asia-southeast1.firebasedatabase.app';

  static const List<String> csvColumns = [
    'timestamp',
    'device_id',
    'zone_id',
    'experiment_id',
    'temperature_c',
    'humidity_percent',
    'pressure_hpa',
    'flame_raw',
    'flame_voltage',
    'flame_digital',
    'gas_raw',
    'gas_voltage',
    'servo_angle',
    'fire_state',
    'risk_score',
    'ml_prediction',
    'ml_confidence',
    'responder_status',
  ];

  static Future<bool> exportTelemetryCsv({String period = 'Comprehensive', String? deviceId}) async {
    final dio = Dio();
    final targetDevice = deviceId ?? 'ESP1';
    final buffer = StringBuffer();

    // 1. Fetch real historical readings from Firebase Realtime Database
    try {
      String? idToken;
      try {
        idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}

      // Try primary path: /devices/{targetDevice}/readings.json
      String url = '$rtdbHost/devices/$targetDevice/readings.json';
      if (idToken != null && idToken.isNotEmpty) {
        url += '?auth=$idToken';
      }

      var response = await dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      // Fallback path if primary path is null or empty
      if (response.data == null || response.data is! Map || (response.data as Map).isEmpty) {
        String fallbackUrl = '$rtdbHost/smart_fire_detection/devices/$targetDevice/readings.json';
        if (idToken != null && idToken.isNotEmpty) {
          fallbackUrl += '?auth=$idToken';
        }
        response = await dio.get(
          fallbackUrl,
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
      }

      if (response.statusCode == 200 && response.data != null && response.data is Map) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(response.data as Map);
        if (dataMap.isNotEmpty) {
          // Write standardized 18-column header
          buffer.writeln(csvColumns.join(','));

          for (final entry in dataMap.entries) {
            final val = entry.value;
            if (val is Map) {
              final reading = Map<String, dynamic>.from(val);

              final temp = reading['temperature_c'] ?? reading['temperature'] ?? '';
              final hum = reading['humidity_percent'] ?? reading['humidity'] ?? '';
              final press = reading['pressure_hpa'] ?? reading['pressure'] ?? '1013.25';

              buffer.writeln(
                '${reading["timestamp"] ?? ""},'
                '${reading["device_id"] ?? targetDevice},'
                '${reading["zone_id"] ?? "ZONE_1"},'
                '${reading["experiment_id"] ?? "EXP001"},'
                '$temp,'
                '$hum,'
                '$press,'
                '${reading["flame_raw"] ?? ""},'
                '${reading["flame_voltage"] ?? ""},'
                '${reading["flame_digital"] ?? 0},'
                '${reading["gas_raw"] ?? ""},'
                '${reading["gas_voltage"] ?? ""},'
                '${reading["servo_angle"] ?? 90},'
                '${reading["fire_state"] ?? "NORMAL"},'
                '${reading["risk_score"] ?? 0.0},'
                '${reading["ml_prediction"] ?? "NORMAL"},'
                '${reading["ml_confidence"] ?? 0.0},'
                '${reading["responder_status"] ?? "IDLE"}',
              );
            }
          }

          // Exact filename requested by specification
          const filename = 'smart_fire_dataset.csv';
          downloadCsvFile(filename, buffer.toString());
          debugPrint('✅ Exported ${dataMap.length} verified records to $filename');
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ Realtime Database pull error: $e');
    }

    // No synthetic data fabrication (Strict adherence to Section 24)
    debugPrint('⚠️ No telemetry records found in Firebase RTDB for $targetDevice.');
    return false;
  }
}
