import 'package:flutter/material.dart';
import 'package:fireshield_app/presentation/common/widgets/custom_text_field.dart';
import 'package:fireshield_app/presentation/common/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your email address and we will send you a link to reset your password.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              const CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Send Reset Link',
                onPressed: () {
                  // Mock reset link functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset link sent!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
