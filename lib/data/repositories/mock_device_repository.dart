import 'dart:async';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';

class MockDeviceRepository implements DeviceRepository {
  final StreamController<List<DeviceModel>> _deviceController = StreamController<List<DeviceModel>>.broadcast();
  
  final List<DeviceModel> _mockDatabase = [
    DeviceModel(
      id: 'dev_001',
      name: 'Kitchen Fire Node (ESP1)',
      room: 'Kitchen',
      latitude: 37.7749,
      longitude: -122.4194,
      firmwareVersion: 'v2.0-AI',
      isOnline: true,
      batteryLevel: 85,
      wifiSignalStrength: 90,
      lastSync: DateTime.now().subtract(const Duration(seconds: 10)),
      flameRaw: 820,
      fireAngle: 90,
      riskScore: 12.5,
      fireState: 'SAFE',
      responseStatus: 'IDLE',
    ),
    DeviceModel(
      id: 'dev_002',
      name: 'Server Room Monitor',
      room: 'Server Room',
      latitude: 37.7749,
      longitude: -122.4194,
      firmwareVersion: 'v1.2.3',
      isOnline: true,
      batteryLevel: 100,
      wifiSignalStrength: 75,
      lastSync: DateTime.now().subtract(const Duration(minutes: 5)),
      flameRaw: 910,
      fireAngle: 45,
      riskScore: 5.0,
      fireState: 'SAFE',
      responseStatus: 'IDLE',
    ),
    DeviceModel(
      id: 'dev_003',
      name: 'Lobby Fire Alarm',
      room: 'Lobby',
      latitude: 37.7749,
      longitude: -122.4194,
      firmwareVersion: 'v1.1.0',
      isOnline: false,
      batteryLevel: 15,
      wifiSignalStrength: 0,
      lastSync: DateTime.now().subtract(const Duration(days: 1)),
      flameRaw: 0,
      fireAngle: 0,
      riskScore: 0.0,
      fireState: 'SAFE',
      responseStatus: 'IDLE',
    ),
  ];

  MockDeviceRepository() {
    Future.microtask(() => _deviceController.add(List.from(_mockDatabase)));
  }

  @override
  Stream<List<DeviceModel>> getDevices() => _deviceController.stream;

  @override
  Future<void> addDevice(DeviceModel device) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockDatabase.add(device);
    _deviceController.add(List.from(_mockDatabase));
  }

  @override
  Future<void> updateDevice(DeviceModel device) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDatabase.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _mockDatabase[index] = device;
      _deviceController.add(List.from(_mockDatabase));
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockDatabase.removeWhere((d) => d.id == deviceId);
    _deviceController.add(List.from(_mockDatabase));
  }

  @override
  Future<void> toggleSimulatedFire(String deviceId) async {
    final index = _mockDatabase.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      final current = _mockDatabase[index];
      final isCurrentlyFire = current.fireState == 'FIRE';
      _mockDatabase[index] = current.copyWith(
        fireState: isCurrentlyFire ? 'SAFE' : 'FIRE',
        riskScore: isCurrentlyFire ? 10.0 : 98.5,
        flameRaw: isCurrentlyFire ? 820 : 140,
        ambientTemperature: isCurrentlyFire ? 24.5 : 68.5,
        smokeRaw: isCurrentlyFire ? 110 : 850,
        gasRaw: isCurrentlyFire ? 120 : 620,
        fireAngle: isCurrentlyFire ? 90 : 45,
        responseStatus: isCurrentlyFire ? 'IDLE' : 'ACTIVE',
      );
      _deviceController.add(List.from(_mockDatabase));
    }
  }

  @override
  Future<void> simulateScenario(String scenario, {String? deviceId}) async {
    final targetId = deviceId ?? 'dev_001';
    final index = _mockDatabase.indexWhere((d) => d.id == targetId);
    if (index != -1) {
      final current = _mockDatabase[index];
      if (scenario == 'FIRE') {
        _mockDatabase[index] = current.copyWith(
          fireState: 'FIRE',
          riskScore: 99.2,
          flameRaw: 95,
          ambientTemperature: 76.5,
          smokeRaw: 890,
          gasRaw: 640,
          fireAngle: 45,
          responseStatus: 'ACTIVE',
        );
      } else if (scenario == 'FALSE_ALARM') {
        _mockDatabase[index] = current.copyWith(
          fireState: 'WARNING',
          riskScore: 35.0,
          flameRaw: 810,
          ambientTemperature: 31.5,
          smokeRaw: 340,
          gasRaw: 450,
          fireAngle: 90,
          responseStatus: 'IDLE',
        );
      } else {
        // NORMAL
        _mockDatabase[index] = current.copyWith(
          fireState: 'SAFE',
          riskScore: 5.5,
          flameRaw: 860,
          ambientTemperature: 24.5,
          smokeRaw: 110,
          gasRaw: 120,
          fireAngle: 90,
          responseStatus: 'IDLE',
        );
      }
      _deviceController.add(List.from(_mockDatabase));
    }
  }
}
