import 'dart:async';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';

class MockDeviceRepository implements DeviceRepository {
  final StreamController<List<DeviceModel>> _deviceController = StreamController<List<DeviceModel>>.broadcast();
  
  final List<DeviceModel> _mockDatabase = [
    DeviceModel(
      id: 'dev_001',
      name: 'Kitchen Smoke Detector',
      room: 'Kitchen',
      latitude: 37.7749,
      longitude: -122.4194,
      firmwareVersion: 'v1.2.4',
      isOnline: true,
      batteryLevel: 85,
      wifiSignalStrength: 90,
      lastSync: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    DeviceModel(
      id: 'dev_002',
      name: 'Server Room Monitor',
      room: 'Server Room',
      latitude: 37.7749,
      longitude: -122.4194,
      firmwareVersion: 'v1.2.3',
      isOnline: true,
      batteryLevel: 100, // plugged in
      wifiSignalStrength: 75,
      lastSync: DateTime.now().subtract(const Duration(minutes: 5)),
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
    ),
  ];

  MockDeviceRepository() {
    // Initial emit
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
}
