import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/presentation/common/widgets/custom_text_field.dart';
import 'package:fireshield_app/presentation/common/widgets/primary_button.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              const CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              const CustomTextField(
                label: 'Password',
                hint: 'Create a password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 20),
              const CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm your password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Sign Up',
                onPressed: () {
                  // Mock authentication
                  context.go('/');
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
