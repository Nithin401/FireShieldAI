import 'package:flutter/material.dart';
import 'package:fireshield_app/presentation/common/widgets/custom_text_field.dart';
import 'package:fireshield_app/presentation/common/widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 24),
            const CustomTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              initialValue: 'John Doe',
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Email Address',
              hint: 'Enter your email',
              initialValue: 'john.doe@example.com',
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Phone Number',
              hint: 'Enter your phone number',
              initialValue: '+1 555-0198',
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Save Changes',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
