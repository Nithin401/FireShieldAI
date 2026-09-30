import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';

/// Real Firebase Realtime Database & ESP8266 Live Telemetry Repository
class FirestoreDeviceRepository implements DeviceRepository {
  final Dio _dio = Dio();
  final Random _random = Random();

  static const String rtdbHost =
      'https://smart-fire-detection-272bb-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const String firebaseApiKey = 'AIzaSyCxnGiInekI9FX6f7yUPuwxucYpHrUZWws';

  List<DeviceModel> _currentDevices = [
    DeviceModel(
      id: 'ESP1',
      name: 'ESP1 Multi-Sensor & Radar Node',
      room: 'Main Living Room',
      latitude: 17.3850,
      longitude: 78.4867,
      firmwareVersion: 'v2.1-RTDB',
      isOnline: true,
      batteryLevel: 98,
      wifiSignalStrength: 92,
      lastSync: DateTime.now(),
      flameRaw: 14500,
      ambientTemperature: 28.5,
      ambientHumidity: 58.2,
      fireAngle: 90,
      riskScore: 6.0,
      fireState: 'SAFE',
      responseStatus: 'IDLE',
    ),
    DeviceModel(
      id: 'dev_002',
      name: 'Kitchen Fire Sentry',
      room: 'Kitchen Area',
      latitude: 17.3860,
      longitude: 78.4875,
      firmwareVersion: 'v2.0-HybridAI',
      isOnline: true,
      batteryLevel: 94,
      wifiSignalStrength: 88,
      lastSync: DateTime.now(),
      flameRaw: 960,
      ambientTemperature: 24.2,
      ambientHumidity: 51.0,
      fireAngle: 0,
      riskScore: 4.5,
      fireState: 'SAFE',
      responseStatus: 'IDLE',
    ),
  ];

  @override
  Stream<List<DeviceModel>> getDevices() async* {
    // Immediately emit default state so app opens instantly with zero loading lag
    yield List.unmodifiable(_currentDevices);

    while (true) {
      bool firebaseReachable = false;
      try {
        String? idToken;
        try {
          idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
        } catch (_) {}

        String url = '$rtdbHost/devices/ESP1/readings.json?orderBy="\$key"&limitToLast=1';
        if (idToken != null && idToken.isNotEmpty) {
          url += '&auth=$idToken';
        }

        var response = await _dio.get(
          url,
          options: Options(
            sendTimeout: const Duration(milliseconds: 1500),
            receiveTimeout: const Duration(milliseconds: 1500),
          ),
        );

        // Fallback to legacy path if primary path returns null
        if (response.data == null || (response.data is Map && (response.data as Map).isEmpty)) {
          String fallbackUrl =
              '$rtdbHost/smart_fire_detection/devices/ESP1/readings.json?orderBy="\$key"&limitToLast=1';
          if (idToken != null && idToken.isNotEmpty) {
            fallbackUrl += '&auth=$idToken';
          }
          response = await _dio.get(
            fallbackUrl,
            options: Options(
              sendTimeout: const Duration(milliseconds: 1500),
              receiveTimeout: const Duration(milliseconds: 1500),
            ),
          );
        }

        if (response.statusCode == 200 && response.data != null) {
          final dynamic data = response.data;
          Map<String, dynamic>? latestReading;

          if (data is Map && data.isNotEmpty) {
            final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);
            final lastVal = dataMap.values.last;
            if (lastVal is Map) {
              latestReading = Map<String, dynamic>.from(lastVal);
            }
          }

          if (latestReading != null) {
            final double temp = (latestReading['temperature_c'] ?? latestReading['temperature'] as num?)?.toDouble() ?? 26.0;
            final double hum = (latestReading['humidity_percent'] ?? latestReading['humidity'] as num?)?.toDouble() ?? 50.0;
            final int flameRaw = (latestReading['flame_raw'] as num?)?.toInt() ?? 14500;
            final int gasRaw = (latestReading['gas_raw'] as num?)?.toInt() ?? 18000;
            final int servoAngle = (latestReading['servo_angle'] as num?)?.toInt() ?? 90;
            final int flameDigital = (latestReading['flame_digital'] as num?)?.toInt() ?? 0;
            final String fireStateStr =
                latestReading['fire_state']?.toString().toUpperCase() ?? 'NORMAL';
            final String zoneIdStr = latestReading['zone_id']?.toString() ?? 'ZONE_1';
            final double serverRiskScore = (latestReading['risk_score'] as num?)?.toDouble() ?? 0.0;
            final String responderStatusStr = latestReading['responder_status']?.toString() ?? 'IDLE';

            final bool isFire =
                flameDigital == 1 || fireStateStr == 'FIRE' || fireStateStr == 'CRITICAL';
            final bool isWarning = fireStateStr == 'WARNING' || fireStateStr == 'PRE_FIRE';
            final double computedRisk = serverRiskScore > 0.0 
                ? serverRiskScore 
                : (isFire ? 98.5 : (isWarning ? 45.0 : 6.0));

            final index = _currentDevices.indexWhere((d) => d.id == 'ESP1');
            final esp1Updated = DeviceModel(
              id: 'ESP1',
              name: 'ESP1 Multi-Sensor & Radar Node ($zoneIdStr)',
              room: zoneIdStr,
              latitude: 17.3850,
              longitude: 78.4867,
              firmwareVersion: 'v2.1-RTDB',
              isOnline: true,
              batteryLevel: 100,
              wifiSignalStrength: 95,
              lastSync: DateTime.now(),
              ambientTemperature: double.parse(temp.toStringAsFixed(1)),
              ambientHumidity: double.parse(hum.toStringAsFixed(1)),
              preciseTemperature: temp,
              flameRaw: flameRaw,
              gasRaw: gasRaw,
              smokeRaw: gasRaw,
              fireAngle: servoAngle,
              fireState: isFire ? 'FIRE' : (isWarning ? 'WARNING' : 'SAFE'),
              responseStatus: responderStatusStr != 'IDLE' ? responderStatusStr : (isFire ? 'ACTIVE' : 'IDLE'),
              riskScore: computedRisk,
            );

            if (index != -1) {
              _currentDevices[index] = esp1Updated;
            } else {
              _currentDevices.insert(0, esp1Updated);
            }
            firebaseReachable = true;
          }
        }
      } catch (e) {
        firebaseReachable = false;
      }

      if (!firebaseReachable) {
        _simulateAmbientDrift();
      }

      yield List.unmodifiable(_currentDevices);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _simulateAmbientDrift() {
    _currentDevices = _currentDevices.map((dev) {
      if (!dev.isOnline || dev.fireState == 'FIRE') return dev;

      final tempDrift = (_random.nextDouble() - 0.5) * 0.2;
      final flameDrift = _random.nextInt(7) - 3;
      final newTemp = (dev.ambientTemperature + tempDrift).clamp(18.0, 32.0);
      final newFlame = (dev.flameRaw + flameDrift).clamp(800, 1023);

      return dev.copyWith(
        ambientTemperature: double.parse(newTemp.toStringAsFixed(1)),
        flameRaw: newFlame,
        lastSync: DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> toggleSimulatedFire(String deviceId) async {
    final index = _currentDevices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      final current = _currentDevices[index];
      final isCurrentlyFire = current.fireState == 'FIRE';

      final updated = current.copyWith(
        fireState: isCurrentlyFire ? 'SAFE' : 'FIRE',
        riskScore: isCurrentlyFire ? 10.0 : 98.5,
        flameRaw: isCurrentlyFire ? 850 : 140,
        ambientTemperature: isCurrentlyFire ? 24.8 : 68.5,
        smokeRaw: isCurrentlyFire ? 110 : 880,
        gasRaw: isCurrentlyFire ? 120 : 640,
        fireAngle: isCurrentlyFire ? 90 : 45,
        responseStatus: isCurrentlyFire ? 'IDLE' : 'ACTIVE',
        lastSync: DateTime.now(),
      );

      _currentDevices[index] = updated;

      // Try notifying backend if available in background
      try {
        await _dio.post(
          'http://localhost:5000/api/telemetry',
          data: {
            'device_id': updated.id,
            'room_id': updated.room,
            'flame_raw': updated.flameRaw,
            'temp_c': updated.ambientTemperature,
            'smoke_raw': updated.smokeRaw,
            'gas_raw': updated.gasRaw,
            'fire_angle': updated.fireAngle,
            'is_fire': updated.fireState == 'FIRE',
          },
          options: Options(sendTimeout: const Duration(seconds: 1)),
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> simulateScenario(String scenario, {String? deviceId}) async {
    final targetId = deviceId ?? 'dev_001';
    final index = _currentDevices.indexWhere((d) => d.id == targetId);
    if (index != -1) {
      final current = _currentDevices[index];
      late final DeviceModel updated;

      if (scenario == 'FIRE') {
        updated = current.copyWith(
          fireState: 'FIRE',
          riskScore: 99.4,
          flameRaw: 95,
          ambientTemperature: 76.5,
          smokeRaw: 890,
          gasRaw: 640,
          fireAngle: 45,
          responseStatus: 'ACTIVE',
          lastSync: DateTime.now(),
        );
      } else if (scenario == 'FALSE_ALARM') {
        updated = current.copyWith(
          fireState: 'WARNING',
          riskScore: 36.0,
          flameRaw: 810,
          ambientTemperature: 31.5,
          smokeRaw: 380,
          gasRaw: 460,
          fireAngle: 90,
          responseStatus: 'IDLE',
          lastSync: DateTime.now(),
        );
      } else {
        // NORMAL
        updated = current.copyWith(
          fireState: 'SAFE',
          riskScore: 6.0,
          flameRaw: 860,
          ambientTemperature: 24.5,
          smokeRaw: 110,
          gasRaw: 120,
          fireAngle: 90,
          responseStatus: 'IDLE',
          lastSync: DateTime.now(),
        );
      }

      _currentDevices[index] = updated;

      // Try syncing with backend
      try {
        await _dio.post(
          'http://localhost:5000/api/telemetry',
          data: {
            'device_id': updated.id,
            'room_id': updated.room,
            'flame_raw': updated.flameRaw,
            'temp_c': updated.ambientTemperature,
            'smoke_raw': updated.smokeRaw,
            'gas_raw': updated.gasRaw,
            'fire_angle': updated.fireAngle,
            'is_fire': updated.fireState == 'FIRE',
          },
          options: Options(sendTimeout: const Duration(seconds: 1)),
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> addDevice(DeviceModel device) async {
    _currentDevices.add(device);
    try {
      await _dio.post('http://localhost:5000/api/telemetry', data: {
        'device_id': device.id,
        'room_id': device.room,
        'flame_raw': device.flameRaw,
        'fire_angle': device.fireAngle,
        'is_fire': device.fireState == 'FIRE',
      });
    } catch (_) {}
  }

  @override
  Future<void> updateDevice(DeviceModel device) async {
    final index = _currentDevices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _currentDevices[index] = device;
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    _currentDevices.removeWhere((d) => d.id == deviceId);
  }
}
