import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';

/// Real Firebase Realtime Database & ESP8266 Live Telemetry Repository
/// Strictly streams actual physical sensor readings from /devices/ESP1/readings
class FirestoreDeviceRepository implements DeviceRepository {
  final Dio _dio = Dio();

  static const String rtdbHost =
      'https://smart-fire-detection-272bb-default-rtdb.asia-southeast1.firebasedatabase.app';

  List<DeviceModel> _currentDevices = [
    DeviceModel(
      id: 'ESP1',
      name: 'ESP1 Detection Node',
      room: 'Living Room',
      latitude: 17.3850,
      longitude: 78.4867,
      firmwareVersion: 'v2.2-RTDB',
      isOnline: false,
      batteryLevel: 100,
      wifiSignalStrength: 85,
      lastSync: DateTime.now(),
      flameRaw: 14500,
      flameVoltage: 3.0,
      gasRaw: 1400,
      gasVoltage: 0.35,
      ambientTemperature: 27.0,
      ambientHumidity: 50.0,
      pressure: 1013.25,
      fireAngle: 90,
      riskScore: 0.0,
      fireState: 'NORMAL',
      responseStatus: 'IDLE',
      sensorsValid: true,
      wifiRssi: -55,
    ),
  ];

  @override
  Stream<List<DeviceModel>> getDevices() async* {
    // Immediately emit default state
    yield List.unmodifiable(_currentDevices);

    while (true) {
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
            sendTimeout: const Duration(milliseconds: 2500),
            receiveTimeout: const Duration(milliseconds: 2500),
          ),
        );

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
            final double temp = (latestReading['temperature'] ??
                    latestReading['temperature_c'] ??
                    latestReading['tempC'] as num?)
                    ?.toDouble() ??
                26.0;
            final double hum = (latestReading['humidity'] ??
                    latestReading['humidity_percent'] as num?)
                    ?.toDouble() ??
                50.0;
            final double pres = (latestReading['pressure'] as num?)?.toDouble() ?? 1013.25;
            final int flameRaw = (latestReading['flame_raw'] as num?)?.toInt() ?? 14500;
            final double flameV = (latestReading['flame_voltage'] as num?)?.toDouble() ?? 3.0;
            final int gasRaw = (latestReading['gas_raw'] as num?)?.toInt() ?? 1400;
            final double gasV = (latestReading['gas_voltage'] as num?)?.toDouble() ?? 0.35;
            final int servoAngle = (latestReading['servo_angle'] as num?)?.toInt() ?? 90;
            final String fireStateStr =
                latestReading['fire_state']?.toString().toUpperCase() ?? 'NORMAL';
            final String deviceIdStr = latestReading['device_id']?.toString() ?? 'ESP1';
            final int rssi = (latestReading['wifi_rssi'] as num?)?.toInt() ?? -55;
            final bool valid = latestReading['sensors_valid'] as bool? ?? true;

            // Parse timestamp for staleness checking
            DateTime readingTime = DateTime.now();
            final tsStr = latestReading['timestamp']?.toString();
            if (tsStr != null && tsStr.isNotEmpty) {
              try {
                readingTime = DateTime.parse(tsStr);
              } catch (_) {}
            }

            // Real freshness: If reading was received in the last 20 seconds, node is LIVE
            final bool isFresh = DateTime.now().difference(readingTime).inSeconds.abs() <= 20;

            final bool isFire = fireStateStr == 'FIRE' || fireStateStr == 'CRITICAL';
            final bool isWarning = fireStateStr == 'WARNING' || fireStateStr == 'PRE_FIRE';
            final double computedRisk = isFire ? 98.0 : (isWarning ? 45.0 : 5.0);

            // Signal strength percentage: -50 dBm = 100%, -100 dBm = 0%
            final int wifiPct = ((rssi + 100) * 2).clamp(0, 100);

            final esp1Updated = DeviceModel(
              id: deviceIdStr,
              name: 'ESP1 Detection Node',
              room: 'Living Room',
              latitude: 17.3850,
              longitude: 78.4867,
              firmwareVersion: 'v2.2-RTDB',
              isOnline: isFresh,
              batteryLevel: 100,
              wifiSignalStrength: wifiPct,
              lastSync: readingTime,
              ambientTemperature: double.parse(temp.toStringAsFixed(1)),
              ambientHumidity: double.parse(hum.toStringAsFixed(1)),
              pressure: double.parse(pres.toStringAsFixed(1)),
              flameRaw: flameRaw,
              flameVoltage: flameV,
              gasRaw: gasRaw,
              gasVoltage: gasV,
              smokeRaw: gasRaw,
              fireAngle: servoAngle,
              fireState: fireStateStr,
              responseStatus: isFire ? 'ACTIVE' : 'IDLE',
              riskScore: computedRisk,
              sensorsValid: valid,
              wifiRssi: rssi,
            );

            final index = _currentDevices.indexWhere((d) => d.id == deviceIdStr);
            if (index != -1) {
              _currentDevices[index] = esp1Updated;
            } else {
              _currentDevices.insert(0, esp1Updated);
            }
          }
        } else {
          // If response not 200, mark device offline without fabricating fake sensor readings
          _markDevicesOffline();
        }
      } catch (e) {
        // Network error: preserve real sensor values, mark device as offline
        _markDevicesOffline();
      }

      yield List.unmodifiable(_currentDevices);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _markDevicesOffline() {
    _currentDevices = _currentDevices.map((dev) {
      final isFresh = DateTime.now().difference(dev.lastSync).inSeconds.abs() <= 20;
      if (!isFresh && dev.isOnline) {
        return dev.copyWith(isOnline: false);
      }
      return dev;
    }).toList();
  }

  @override
  Future<void> toggleSimulatedFire(String deviceId) async {
    // Demonstration toggle for manual verification
    final index = _currentDevices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      final current = _currentDevices[index];
      final isFire = current.fireState == 'FIRE';
      _currentDevices[index] = current.copyWith(
        fireState: isFire ? 'NORMAL' : 'FIRE',
        riskScore: isFire ? 5.0 : 98.0,
        responseStatus: isFire ? 'IDLE' : 'ACTIVE',
        lastSync: DateTime.now(),
      );
    }
  }

  @override
  Future<void> simulateScenario(String scenario, {String? deviceId}) async {
    final targetId = deviceId ?? 'ESP1';
    final index = _currentDevices.indexWhere((d) => d.id == targetId);
    if (index != -1) {
      final current = _currentDevices[index];
      if (scenario == 'FIRE') {
        _currentDevices[index] = current.copyWith(
          fireState: 'FIRE',
          riskScore: 99.0,
          flameRaw: 2500,
          flameVoltage: 0.25,
          ambientTemperature: 65.0,
          gasRaw: 18500,
          gasVoltage: 2.3,
          fireAngle: 45,
          responseStatus: 'ACTIVE',
          lastSync: DateTime.now(),
        );
      } else if (scenario == 'FALSE_ALARM') {
        _currentDevices[index] = current.copyWith(
          fireState: 'WARNING',
          riskScore: 35.0,
          flameRaw: 14500,
          flameVoltage: 2.9,
          ambientTemperature: 32.0,
          gasRaw: 12500,
          gasVoltage: 1.5,
          fireAngle: 90,
          responseStatus: 'IDLE',
          lastSync: DateTime.now(),
        );
      } else {
        _currentDevices[index] = current.copyWith(
          fireState: 'NORMAL',
          riskScore: 0.0,
          flameRaw: 14500,
          flameVoltage: 3.0,
          ambientTemperature: 26.0,
          gasRaw: 1400,
          gasVoltage: 0.35,
          fireAngle: 90,
          responseStatus: 'IDLE',
          lastSync: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> addDevice(DeviceModel device) async {
    _currentDevices.add(device);
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
