import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Subscription Status'),
            subtitle: const Text('Premium Tier - Active'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Subscription details screen
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Push Notifications'),
            value: true,
            onChanged: (bool value) {
              // TODO: Implement toggle
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: true,
            onChanged: (bool value) {
              // TODO: Implement theme toggle
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'System'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About FireShield AI'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
