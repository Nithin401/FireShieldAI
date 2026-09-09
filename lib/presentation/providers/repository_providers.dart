import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireshield_app/data/repositories/firestore_device_repository.dart';
import 'package:fireshield_app/data/repositories/mock_auth_repository.dart';
import 'package:fireshield_app/data/repositories/mock_device_repository.dart';
import 'package:fireshield_app/data/repositories/mock_hardware_protocol_repository.dart';
import 'package:fireshield_app/data/repositories/mock_report_repository.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/domain/repositories/auth_repository.dart';
import 'package:fireshield_app/domain/repositories/device_repository.dart';
import 'package:fireshield_app/domain/repositories/hardware_protocol_repository.dart';
import 'package:fireshield_app/domain/repositories/report_repository.dart';

// Set to true to stream real telemetry from Python Backend / Firestore; false for static mocks
const bool useRealBackend = true;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  if (useRealBackend) {
    return FirestoreDeviceRepository();
  } else {
    return MockDeviceRepository();
  }
});

final hardwareProtocolRepositoryProvider = Provider<HardwareProtocolRepository>((ref) {
  return MockHardwareProtocolRepository();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return MockReportRepository();
});

final authStateProvider = StreamProvider<String?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final devicesStreamProvider = StreamProvider<List<DeviceModel>>((ref) {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return deviceRepo.getDevices();
});
