import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/core/services/emergency_dispatch_service.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;

  @override
  Widget build(BuildContext context) {
    final dispatchService = EmergencyDispatchService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Connected Devices'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Connected Device Notifications
          _buildSectionHeader(context, 'Connected Device Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active, color: Colors.blue),
            title: const Text('Device Push Notifications & Audio Siren'),
            subtitle: const Text('Receive OS-level push banners and audio alerts on this device'),
            value: _pushEnabled,
            onChanged: (bool value) {
              setState(() {
                _pushEnabled = value;
              });
              if (value) {
                requestNotificationPermission();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.phonelink_ring, color: Colors.amber),
            title: const Text('Send Test Alert to this Device'),
            subtitle: const Text('Verify browser/system push notifications and emergency speaker audio'),
            trailing: const Icon(Icons.send),
            onTap: () {
              requestNotificationPermission();
              triggerSystemNotification(
                '🔔 FireShield AI Device Test',
                'Your device is connected and ready to receive real-time fire and abnormal heat alerts!',
                'critical',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.blue,
                  content: Text('🔔 Test notification sent to your device! If prompted, tap Allow.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          const Divider(height: 32),

          // Section 2: User Emergency Contacts
          _buildSectionHeader(context, 'Emergency Mail & Message Dispatch'),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Color(0xFF38BDF8)),
            title: const Text('Emergency Mail'),
            subtitle: Text(dispatchService.userEmail),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.sms_outlined, color: Colors.green),
            title: const Text('Emergency Messages / SMS'),
            subtitle: Text(dispatchService.userPhone),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          const Divider(height: 32),

          // Section 3: Add to Phone Home Screen
          _buildSectionHeader(context, 'Install App on Your Phone (PWA)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.install_mobile, color: Colors.cyan, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'How to get notifications on your phone:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '1. Open this link on your phone (Chrome on Android or Safari on iPhone).\n'
                  '2. Tap "Install App" or "Add to Home Screen" from browser menu.\n'
                  '3. Tap "Allow" when asked for Notification permissions.\n'
                  '4. Your phone will receive full push notifications, vibration, and siren alerts!',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // Section 4: Account & System
          _buildSectionHeader(context, 'Account & Profile'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile Details'),
            subtitle: const Text('Update name, alert email, and phone number'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
