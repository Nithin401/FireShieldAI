import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fireshield_app/domain/models/device_model.dart';

part 'device_providers.g.dart';

@riverpod
class MockDevices extends _$MockDevices {
  @override
  List<DeviceModel> build() {
    return [
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
  }
}
