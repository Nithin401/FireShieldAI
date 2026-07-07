import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/presentation/common/widgets/custom_text_field.dart';
import 'package:fireshield_app/presentation/common/widgets/primary_button.dart';

class AddDeviceScreen extends StatelessWidget {
  const AddDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Device'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CustomTextField(
              label: 'Device ID / Serial Number',
              hint: 'e.g., FS-2026-XYZ',
              prefixIcon: Icons.qr_code,
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Device Name',
              hint: 'e.g., Kitchen Smoke Detector',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Room / Location',
              hint: 'e.g., Kitchen',
              prefixIcon: Icons.room_outlined,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Add Device',
              onPressed: () {
                // Mock adding device
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device added successfully!')),
                );
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
