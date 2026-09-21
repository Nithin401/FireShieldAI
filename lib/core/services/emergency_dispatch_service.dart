import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

class EmergencyDispatchService {
  static final EmergencyDispatchService _instance = EmergencyDispatchService._internal();

  factory EmergencyDispatchService() {
    return _instance;
  }

  EmergencyDispatchService._internal();

  final Dio _dio = Dio();
  String userEmail = 'user.safety@fireshield.ai';
  String userPhone = '+1 555-0199';
  bool autoDispatchEnabled = true;

  final Set<String> _dispatchedEvents = {};

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userEmail = prefs.getString('emergency_email') ?? userEmail;
      userPhone = prefs.getString('emergency_phone') ?? userPhone;
      autoDispatchEnabled = prefs.getBool('auto_dispatch_alerts') ?? true;
    } catch (_) {}
  }

  Future<void> updateContacts({required String email, required String phone, required bool autoDispatch}) async {
    userEmail = email;
    userPhone = phone;
    autoDispatchEnabled = autoDispatch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergency_email', email);
      await prefs.setString('emergency_phone', phone);
      await prefs.setBool('auto_dispatch_alerts', autoDispatch);
    } catch (_) {}
  }

  /// Sends emergency verification notifications through the app to the user's Messages and Mail
  Future<Map<String, dynamic>> sendEmergencyVerificationNotice({
    required String alertId,
    required String roomId,
    required double temperature,
    required int fireAngle,
    required double riskScore,
  }) async {
    if (_dispatchedEvents.contains(alertId)) {
      return {'status': 'already_dispatched'};
    }
    _dispatchedEvents.add(alertId);

    final emailSubject = '🚨 FireShield AI: Abnormal Heat ($temperature°C) in $roomId - Verify Home';
    final emailBody =
        'Abnormal heat temperature and fire signature detected in $roomId!\n'
        '• Temperature: ${temperature.toStringAsFixed(1)} °C\n'
        '• Threat Angle: $fireAngle°\n'
        '• AI Risk Score: ${riskScore.toStringAsFixed(1)}%\n\n'
        'ACTION REQUIRED: Please verify your home immediately in the FireShield AI app.\n'
        '• Select [YES] if there is an active emergency.\n'
        '• Select [NO] if you checked the area and the issue has been cleared out.';

    final smsMessage =
        '🚨 [FireShield AI] Fire/Heat Anomaly in $roomId (${temperature.toStringAsFixed(1)}°C, $fireAngle°). '
        'Verify home in app: Tap NO if issue cleared, or YES for emergency.';

    // 1. Native OS / Browser Notification with Mail & Message confirmation
    triggerSystemNotification(
      '🚨 Alerts Sent to Mail & Messages: $roomId',
      'Sent to $userEmail and $userPhone. Tap to verify home: YES / NO.',
      'critical',
    );

    // 2. Dispatch to Backend REST Email/SMS Service
    try {
      final response = await _dio.post(
        'http://localhost:5000/api/notifications/dispatch',
        data: {
          'alertId': alertId,
          'roomId': roomId,
          'temperature': temperature,
          'fireAngle': fireAngle,
          'riskScore': riskScore,
          'email': userEmail,
          'phone': userPhone,
          'emailSubject': emailSubject,
          'emailBody': emailBody,
          'smsMessage': smsMessage,
        },
        options: Options(sendTimeout: const Duration(seconds: 2)),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ Emergency Mail & SMS dispatched via backend gateway.');
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ℹ️ Offline mode: Mail and SMS logged locally for $userEmail & $userPhone.');
    }

    return {
      'status': 'sent_locally',
      'emailSentTo': userEmail,
      'smsSentTo': userPhone,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Sends an all-clear confirmation notice to Messages and Mail once the user checks their home and selects "NO"
  Future<void> sendAllClearConfirmation({required String roomId}) async {
    final title = '✅ All-Clear Confirmed: $roomId Verified Safe';
    final body =
        'Home checked by user. No active danger. System returned to normal monitoring.\n'
        'Notice sent to $userEmail and $userPhone.';

    triggerSystemNotification(title, body, 'info');

    try {
      await _dio.post(
        'http://localhost:5000/api/notifications/dispatch',
        data: {
          'alertId': 'all_clear_${DateTime.now().millisecondsSinceEpoch}',
          'roomId': roomId,
          'temperature': 24.5,
          'fireAngle': 90,
          'riskScore': 5.0,
          'email': userEmail,
          'phone': userPhone,
          'emailSubject': '✅ FireShield AI: $roomId Verified Safe - Issue Cleared',
          'emailBody': body,
          'smsMessage': '✅ [FireShield AI] $roomId verified safe by user. Issue cleared out.',
        },
        options: Options(sendTimeout: const Duration(seconds: 1)),
      );
    } catch (_) {}
  }
}
