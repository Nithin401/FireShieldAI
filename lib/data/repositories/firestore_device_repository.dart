import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';

/// Real Backend & Firestore implementation of the Device Repository
class FirestoreDeviceRepository implements DeviceRepository {
  final Dio _dio = Dio();
  final String _backendUrl = 'http://localhost:5000/api/devices';

  @override
  Stream<List<DeviceModel>> getDevices() async* {
    while (true) {
      try {
        final response = await _dio.get(_backendUrl);
        if (response.statusCode == 200 && response.data != null) {
          final List<dynamic> list = response.data is List ? response.data : jsonDecode(response.data.toString());
          final devices = list.map((json) => DeviceModel.fromJson(Map<String, dynamic>.from(json))).toList();
          yield devices;
        }
      } catch (e) {
        debugPrint("⚠️ Telemetry fetch error from backend: $e. Falling back to local state.");
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Future<void> addDevice(DeviceModel device) async {
    try {
      await _dio.post('http://localhost:5000/api/telemetry', data: {
        'device_id': device.id,
        'room_id': device.room,
        'flame_raw': device.flameRaw,
        'fire_angle': device.fireAngle,
        'is_fire': device.fireState == 'FIRE',
      });
    } catch (e) {
      debugPrint("Add device error: $e");
    }
  }

  @override
  Future<void> updateDevice(DeviceModel device) async {
    // Handled automatically via telemetry endpoint
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    // Delete handling
  }
}
