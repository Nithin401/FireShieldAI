import 'package:flutter_test/flutter_test.dart';
import 'package:fireshield_app/data/repositories/flask_device_repository.dart';
import 'package:fireshield_app/core/services/flask_api_service.dart';

void main() {
  group('Flask Integration and Mapping Tests', () {
    test('FlaskApiService default base URL is set for environment', () {
      final service = FlaskApiService();
      expect(service.currentBaseUrl, isNotEmpty);
      expect(service.currentBaseUrl, startsWith('http'));
    });

    test('FlaskDeviceRepository initial state contains valid placeholder', () async {
      final repo = FlaskDeviceRepository();
      final devicesStream = repo.getDevices();
      final initialDevices = await devicesStream.first;

      expect(initialDevices, isNotEmpty);
      expect(initialDevices.first.id, 'ESP1');
      expect(initialDevices.first.firmwareVersion, contains('ThingSpeak'));
    });
  });
}
