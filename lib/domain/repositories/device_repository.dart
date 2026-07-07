import 'package:fireshield_app/domain/models/device_model.dart';

abstract class DeviceRepository {
  Stream<List<DeviceModel>> getDevices();
  Future<void> addDevice(DeviceModel device);
  Future<void> updateDevice(DeviceModel device);
  Future<void> deleteDevice(String deviceId);
}
