import 'dart:async';
import 'package:fireshield_app/domain/repositories/hardware_protocol_repository.dart';

class MockHardwareProtocolRepository implements HardwareProtocolRepository {
  @override
  Future<bool> connectToBridge(String deviceId) async {
    // Simulate MQTT/BLE connection delay
    await Future.delayed(const Duration(seconds: 2));
    return true; // Simulate successful connection
  }

  @override
  Future<void> sendPairingSequence(String deviceId) async {
    // Simulate BLE pairing handshake
    await Future.delayed(const Duration(seconds: 3));
  }

  @override
  Stream<Map<String, dynamic>> streamDiagnosticData(String deviceId) async* {
    // Simulate an MQTT stream of real-time sensor data
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield {
        'deviceId': deviceId,
        'temperature': 22.0 + (DateTime.now().second % 5), // fluctuating mock data
        'co_ppm': 0.5 + (DateTime.now().millisecond % 3),
        'battery': 85,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<void> triggerFirmwareUpdate(String deviceId, String firmwareUrl) async {
    // Simulate OTA command
    await Future.delayed(const Duration(seconds: 1));
  }
}
