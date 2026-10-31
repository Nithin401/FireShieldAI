import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fireshield_app/core/services/flask_api_service.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';

/// Concrete DeviceRepository implementation fetching real ThingSpeak readings via Flask API,
/// with automatic direct ThingSpeak HTTPS fallback when Flask backend is not reachable.
/// Avoids Firebase completely and maintains strictly local/ThingSpeak telemetry.
class FlaskDeviceRepository implements DeviceRepository {
  FlaskDeviceRepository({FlaskApiService? apiService})
      : _api = apiService ?? FlaskApiService(),
        _thingSpeakDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );

  final FlaskApiService _api;
  final Dio _thingSpeakDio;

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
    await _pollTelemetry();
    yield List<DeviceModel>.from(_devices);

    while (true) {
      await Future.delayed(const Duration(seconds: 4));
      await _pollTelemetry();
      yield List<DeviceModel>.from(_devices);
    }
  }

  Future<void> _pollTelemetry() async {
    bool success = false;
    // 1. Try Flask Backend first (contains rich baseline & risk calculations)
    try {
      final res = await _api.getLatestReading();
      if (res != null && res['success'] == true && res['reading'] != null) {
        final reading = Map<String, dynamic>.from(res['reading'] as Map);
        _updateFromReading(reading);
        success = true;
      }
    } catch (e) {
      debugPrint('Flask backend unavailable, attempting direct ThingSpeak fallback: $e');
    }

    // 2. If Flask is not running, fall back directly to ThingSpeak channel 3534677 over HTTPS!
    if (!success) {
      try {
        final resp = await _thingSpeakDio.get(
          'https://api.thingspeak.com/channels/3534677/feeds/last.json',
          queryParameters: {'api_key': 'KGGT6DMKNSCA6FS6'},
        );
        if (resp.statusCode == 200 && resp.data is Map) {
          final feed = Map<String, dynamic>.from(resp.data as Map);
          if (feed.containsKey('field1') || feed.containsKey('field3')) {
            final flameRaw = int.tryParse(feed['field1']?.toString() ?? '') ?? 1024;
            final smokeStatus = int.tryParse(feed['field2']?.toString() ?? '') ?? 0;
            final temp = double.tryParse(feed['field3']?.toString() ?? '') ?? 25.0;
            final hum = double.tryParse(feed['field4']?.toString() ?? '') ?? 50.0;
            final servo = int.tryParse(feed['field5']?.toString() ?? '') ?? 90;
            final fireStatus = int.tryParse(feed['field6']?.toString() ?? '') ?? 0;

            final simulatedReading = {
              'flame_raw': flameRaw,
              'smoke_status': smokeStatus,
              'temperature_c': temp,
              'humidity_pct': hum,
              'servo_angle': servo,
              'fire_status': fireStatus,
              'is_stale': false,
              'created_at': feed['created_at'],
            };
            _updateFromReading(simulatedReading);
            success = true;
            debugPrint('✅ Direct ThingSpeak telemetry successfully retrieved in Flutter app!');
          }
        }
      } catch (tsErr) {
        debugPrint('Direct ThingSpeak fallback also unavailable: $tsErr');
      }
    }

    if (!success && _devices.isNotEmpty) {
      _devices[0] = _devices[0].copyWith(
        isOnline: false,
        sensorsValid: false,
      );
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
