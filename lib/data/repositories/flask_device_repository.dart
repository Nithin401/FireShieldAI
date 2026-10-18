import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fireshield_app/core/services/flask_api_service.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';

/// Concrete DeviceRepository implementation fetching real ThingSpeak readings via Flask API.
/// Avoids Firebase completely and maintains strictly local/ThingSpeak telemetry.
class FlaskDeviceRepository implements DeviceRepository {
  FlaskDeviceRepository({FlaskApiService? apiService})
      : _api = apiService ?? FlaskApiService();

  final FlaskApiService _api;

  final List<DeviceModel> _devices = [
    DeviceModel(
      id: 'ESP1',
      name: 'ESP8266 Detection Node',
      room: 'Living Room',
      latitude: 17.3850,
      longitude: 78.4867,
      firmwareVersion: 'v1.0-ThingSpeak',
      isOnline: false,
      batteryLevel: 100,
      wifiSignalStrength: 85,
      lastSync: DateTime.now(),
      flameRaw: 1024,
      flameVoltage: 3.3,
      gasRaw: 0,
      gasVoltage: 0.0,
      ambientTemperature: 25.0,
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
    // Attempt initial fetch immediately
    try {
      final res = await _api.getLatestReading();
      if (res != null && res['success'] == true && res['reading'] != null) {
        final reading = Map<String, dynamic>.from(res['reading'] as Map);
        _updateFromReading(reading);
      }
    } catch (e) {
      debugPrint('FlaskDeviceRepository initial poll: $e');
    }

    yield List<DeviceModel>.from(_devices);

    while (true) {
      await Future.delayed(const Duration(seconds: 4));
      try {
        final res = await _api.getLatestReading();
        if (res != null && res['success'] == true && res['reading'] != null) {
          final reading = Map<String, dynamic>.from(res['reading'] as Map);
          _updateFromReading(reading);
        } else {
          // If response unavailable, mark device as offline/stale
          if (_devices.isNotEmpty) {
            _devices[0] = _devices[0].copyWith(
              isOnline: false,
              sensorsValid: false,
            );
          }
        }
      } catch (e) {
        debugPrint('FlaskDeviceRepository poll error: $e');
      }

      yield List<DeviceModel>.from(_devices);
    }
  }

  void _updateFromReading(Map<String, dynamic> r) {
    if (_devices.isEmpty) return;

    final flameRaw = (r['flame_raw'] as num?)?.toInt() ?? 1024;
    final smokeStatus = (r['smoke_status'] as num?)?.toInt() ?? 0;
    final temp = (r['temperature_c'] as num?)?.toDouble() ?? 25.0;
    final hum = (r['humidity_pct'] as num?)?.toDouble() ?? 50.0;
    final servo = (r['servo_angle'] as num?)?.toInt() ?? 90;
    final fireStatus = (r['fire_status'] as num?)?.toInt() ?? 0;
    final isStale = r['is_stale'] as bool? ?? true;

    DateTime syncTime = DateTime.now();
    if (r['created_at'] != null) {
      try {
        syncTime = DateTime.parse(r['created_at'].toString());
      } catch (_) {}
    }

    String fireState = 'NORMAL';
    if (fireStatus == 1) {
      fireState = 'FIRE';
    }

    final double flameVolt = (flameRaw / 1023.0) * 3.3;
    final double gasVolt = smokeStatus == 1 ? 3.3 : 0.0;

    _devices[0] = _devices[0].copyWith(
      flameRaw: flameRaw,
      flameVoltage: flameVolt,
      smokeRaw: smokeStatus,
      gasRaw: smokeStatus,
      gasVoltage: gasVolt,
      ambientTemperature: temp,
      ambientHumidity: hum,
      fireAngle: servo,
      fireState: fireState,
      isOnline: !isStale,
      sensorsValid: true,
      lastSync: syncTime,
    );
  }

  @override
  Future<void> addDevice(DeviceModel device) async {
    _devices.add(device);
  }

  @override
  Future<void> updateDevice(DeviceModel device) async {
    final idx = _devices.indexWhere((d) => d.id == device.id);
    if (idx != -1) {
      _devices[idx] = device;
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    _devices.removeWhere((d) => d.id == deviceId);
  }

  @override
  Future<void> toggleSimulatedFire(String deviceId) async {
    final idx = _devices.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      final current = _devices[idx];
      final isFire = current.fireState == 'FIRE';
      _devices[idx] = current.copyWith(
        fireState: isFire ? 'NORMAL' : 'FIRE',
        flameRaw: isFire ? 850 : 250,
      );
    }
  }

  @override
  Future<void> simulateScenario(String scenario, {String? deviceId}) async {
    if (_devices.isEmpty) return;
    if (scenario == 'fire') {
      _devices[0] = _devices[0].copyWith(
        fireState: 'FIRE',
        flameRaw: 200,
        smokeRaw: 1,
      );
    } else {
      _devices[0] = _devices[0].copyWith(
        fireState: 'NORMAL',
        flameRaw: 900,
        smokeRaw: 0,
      );
    }
  }
}
