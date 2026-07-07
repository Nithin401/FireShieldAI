import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireshield_app/data/repositories/mock_auth_repository.dart';
import 'package:fireshield_app/data/repositories/mock_device_repository.dart';
import 'package:fireshield_app/data/repositories/mock_hardware_protocol_repository.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/auth_repository.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';
import 'package:fireshield_app/domain/repositories/hardware_protocol_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Return the mock implementation for now since Firebase isn't configured
  return MockAuthRepository();
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return MockDeviceRepository();
});

final hardwareProtocolRepositoryProvider = Provider<HardwareProtocolRepository>((ref) {
  return MockHardwareProtocolRepository();
});

final authStateProvider = StreamProvider<String?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final devicesStreamProvider = StreamProvider<List<DeviceModel>>((ref) {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return deviceRepo.getDevices();
});
