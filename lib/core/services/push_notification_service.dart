import 'package:flutter/material.dart';

/// Service to handle Firebase Cloud Messaging (FCM)
/// For receiving "Smart Alerts" triggered by the Cloud Function
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  Future<void> initialize() async {
    // In a real Firebase setup, we would call:
    // await FirebaseMessaging.instance.requestPermission();
    // String? token = await FirebaseMessaging.instance.getToken();
    // print("FCM Token: $token");

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   _handleForegroundMessage(message);
    // });
    
    debugPrint("✅ PushNotificationService (Simulated) Initialized.");
  }

  void simulateIncomingFireAlert(BuildContext context, String deviceId) {
    // Simulate what happens when FCM receives an alert
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text('FIRE ALERT DETECTED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Abnormal thermal spike on $deviceId.\\n\\nEvacuate immediately!',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to Emergency SOS Screen (Module 12)
            },
            child: const Text('OPEN EMERGENCY PANEL'),
          ),
        ],
      ),
    );
  }
}
