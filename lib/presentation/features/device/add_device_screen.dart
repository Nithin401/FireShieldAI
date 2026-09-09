import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/presentation/common/widgets/custom_text_field.dart';
import 'package:fireshield_app/presentation/common/widgets/primary_button.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Detection Node'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _idController,
              label: 'Device ID / Serial Number',
              hint: 'e.g., dev_001',
              prefixIcon: Icons.qr_code,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              label: 'Device Name',
              hint: 'e.g., Kitchen Fire Node',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _roomController,
              label: 'Room / Location',
              hint: 'e.g., Kitchen',
              prefixIcon: Icons.room_outlined,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Register Device',
              onPressed: () async {
                final id = _idController.text.trim();
                final name = _nameController.text.trim();
                final room = _roomController.text.trim();

                if (id.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in Device ID and Name')),
                  );
                  return;
                }

                final newDevice = DeviceModel(
                  id: id,
                  name: name,
                  room: room.isEmpty ? 'Main Hall' : room,
                  latitude: 37.7749,
                  longitude: -122.4194,
                  firmwareVersion: 'v2.0-AI',
                  isOnline: true,
                  batteryLevel: 100,
                  wifiSignalStrength: 95,
                  lastSync: DateTime.now(),
                );

                await ref.read(deviceRepositoryProvider).addDevice(newDevice);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Device $id registered successfully!')),
                  );
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
