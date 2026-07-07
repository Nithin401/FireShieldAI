abstract class HardwareProtocolRepository {
  /// Connects to the local network or Bluetooth bridge to find hardware
  Future<bool> connectToBridge(String deviceId);
  
  /// Sends a pairing sequence to the hardware device
  Future<void> sendPairingSequence(String deviceId);
  
  /// Streams real-time raw diagnostic data (MQTT/BLE) directly from hardware
  Stream<Map<String, dynamic>> streamDiagnosticData(String deviceId);
  
  /// Triggers an OTA (Over-the-Air) firmware update command
  Future<void> triggerFirmwareUpdate(String deviceId, String firmwareUrl);
}
