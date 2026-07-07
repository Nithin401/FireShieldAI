import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/presentation/common/widgets/custom_text_field.dart';
import 'package:fireshield_app/presentation/common/widgets/primary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.local_fire_department,
                size: 80,
                color: Colors.red, // Using primary color from theme
              ),
              const SizedBox(height: 24),
              Text(
                'FireShield AI',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to monitor your devices',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),
              const CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              const CustomTextField(
                label: 'Password',
                hint: 'Enter your password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Sign In',
                onPressed: () {
                  // Mock authentication
                  context.go('/');
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Sign Up'),
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
