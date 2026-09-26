import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
bool _isNotificationInitialized = false;
const MethodChannel _telephonyChannel = MethodChannel('fireshield/telephony');

Future<void> _ensureNotificationInitialized() async {
  if (_isNotificationInitialized) return;
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(settings: initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fireshield_emergency_channel',
      'FireShield Emergency Siren & Lockscreen Alerts',
      description: 'Critical life-safety alarms and fire detection notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isNotificationInitialized = true;
  } catch (e) {
    debugPrint('⚠️ Notification initialization failed: $e');
  }
}

void triggerSystemNotification(String title, String body, String severity) async {
  if (kIsWeb) return;

  try {
    await _ensureNotificationInitialized();

    // 1. Wake the screen and illuminate lockscreen on Android
    try {
      await _telephonyChannel.invokeMethod('wakeScreenAndAlert');
    } catch (_) {}

    final isCritical = severity == 'critical' || severity == 'fire';

    // 2. Play audible hardware alarm siren if critical
    if (isCritical) {
      try {
        await _telephonyChannel.invokeMethod('playAlarmSiren');
      } catch (_) {}
    }

    // 3. Show full-screen intent lockscreen notification
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fireshield_emergency_channel',
      'FireShield Emergency Siren & Lockscreen Alerts',
      channelDescription: 'Critical life-safety alarms and fire detection notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: isCritical,
      autoCancel: !isCritical,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  } catch (e) {
    debugPrint('⚠️ Native notification dispatch failed: $e');
  }
}

void requestNotificationPermission() async {
  if (kIsWeb) return;
  try {
    await _ensureNotificationInitialized();
    await Permission.notification.request();
  } catch (_) {}
}

void openExternalUrl(String url) async {
  if (kIsWeb) return;
  try {
    await _telephonyChannel.invokeMethod('openUrl', {'url': url});
  } catch (e) {
    debugPrint('⚠️ Failed to open external URL via native intent: $e');
  }
}

void makeAiEmergencyVoiceCall(String text) async {
  if (kIsWeb) return;
  try {
    await _telephonyChannel.invokeMethod('wakeScreenAndAlert');
    await _telephonyChannel.invokeMethod('playAlarmSiren');
  } catch (_) {}
}

void stopAiVoiceCall() async {
  if (kIsWeb) return;
  try {
    await _telephonyChannel.invokeMethod('stopAlarmSiren');
  } catch (_) {}
}

void downloadCsvFile(String filename, String content) async {
  if (kIsWeb) return;
  try {
    final encoded = Uri.encodeComponent(content);
    await _telephonyChannel.invokeMethod('openUrl', {'url': 'data:text/csv;charset=utf-8,$encoded'});
  } catch (e) {
    debugPrint('⚠️ CSV export intent failed: $e');
  }
}


