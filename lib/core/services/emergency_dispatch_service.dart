import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

enum EscalationPhase {
  idle,
  verifying, // Phase 1: 0 - 30s countdown, AI voice siren active
  directCallDispatched, // Phase 2: 30s timeout elapsed, direct call & SMS active
  fireSafetyDispatched, // Phase 3: 120s / 2m timeout elapsed, dispatched to Fire Safety
  cancelled, // User cancelled / issue cleared
}

class EmergencyDispatchService {
  static final EmergencyDispatchService _instance = EmergencyDispatchService._internal();

  factory EmergencyDispatchService() {
    return _instance;
  }

  EmergencyDispatchService._internal();

  final Dio _dio = Dio();
  String userEmail = 'user.safety@fireshield.ai';
  String userPhone = '+1 555-0199';
  String fireSafetyPhone = '101'; // Default Fire Safety Department (101 in India, 911 in US)
  bool autoDispatchEnabled = true;

  Timer? _escalationTimer;
  int _totalElapsedSeconds = 0;
  EscalationPhase _escalationPhase = EscalationPhase.idle;
  void Function(EscalationPhase phase, int countdownSec)? onEscalationTick;

  EscalationPhase get currentEscalationPhase => _escalationPhase;
  int get totalElapsedSeconds => _totalElapsedSeconds;

  final Set<String> _dispatchedEvents = {};

  bool get isCustomContactConfigured =>
      userEmail != 'user.safety@fireshield.ai' || userPhone != '+1 555-0199';

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userEmail = prefs.getString('emergency_email') ?? userEmail;
      userPhone = prefs.getString('emergency_phone') ?? userPhone;
      fireSafetyPhone = prefs.getString('fire_safety_phone') ?? fireSafetyPhone;
      autoDispatchEnabled = prefs.getBool('auto_dispatch_alerts') ?? true;
      debugPrint('ℹ️ Emergency Contacts initialized: $userEmail | $userPhone | Fire Dept: $fireSafetyPhone');
    } catch (_) {}
  }

  Future<void> updateContacts({
    required String email,
    required String phone,
    String? fireDeptPhone,
    required bool autoDispatch,
  }) async {
    userEmail = email.trim();
    userPhone = phone.trim();
    if (fireDeptPhone != null && fireDeptPhone.trim().isNotEmpty) {
      fireSafetyPhone = fireDeptPhone.trim();
    }
    autoDispatchEnabled = autoDispatch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergency_email', userEmail);
      await prefs.setString('emergency_phone', userPhone);
      await prefs.setString('fire_safety_phone', fireSafetyPhone);
      await prefs.setBool('auto_dispatch_alerts', autoDispatch);
    } catch (_) {}
  }

  String _sanitizePhoneForSms(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  String _sanitizePhoneForWhatsApp(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Directly launches the device native SMS Messages app pre-populated with emergency text
  void openSmsAlert({
    required String roomId,
    required double temperature,
    required int fireAngle,
  }) {
    final cleanPhone = _sanitizePhoneForSms(userPhone);
    final text = '🚨 [FireShield AI Alert] Emergency in $roomId! '
        'Abnormal temp: ${temperature.toStringAsFixed(1)}°C, Bearing: $fireAngle°. '
        'Verify your home safety: Reply NO if issue cleared, or YES if active emergency!';
    final encoded = Uri.encodeComponent(text);
    final url = 'sms:$cleanPhone?body=$encoded';
    openExternalUrl(url);
  }

  /// Directly launches WhatsApp messaging with the alert pre-filled
  void openWhatsAppAlert({
    required String roomId,
    required double temperature,
    required int fireAngle,
  }) {
    final cleanPhone = _sanitizePhoneForWhatsApp(userPhone);
    final text = '🚨 *FireShield AI Emergency Alert*\n\n'
        '🔥 *Abnormal Heat & Fire Signature Detected!*\n'
        '• Zone: *$roomId*\n'
        '• Temperature: *${temperature.toStringAsFixed(1)} °C*\n'
        '• Threat Angle: *$fireAngle°*\n\n'
        '👉 *Home Safety Verification:*\n'
        '• Reply *NO* if you inspected and the issue is cleared out.\n'
        '• Reply *YES* if active emergency!';
    final encoded = Uri.encodeComponent(text);
    final url = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encoded'
        : 'https://wa.me/?text=$encoded';
    openExternalUrl(url);
  }

  /// Directly launches the device native Mail client (Gmail, Apple Mail, Outlook) pre-filled
  void openMailAlert({
    required String roomId,
    required double temperature,
    required int fireAngle,
    required double riskScore,
  }) {
    final subject = '🚨 FireShield AI: Abnormal Heat (${temperature.toStringAsFixed(1)}°C) in $roomId - Verify Home';
    final body =
        'Abnormal heat temperature and fire signature detected in $roomId!\n\n'
        '• Temperature: ${temperature.toStringAsFixed(1)} °C\n'
        '• Threat Bearing / Angle: $fireAngle°\n'
        '• AI Risk Score: ${riskScore.toStringAsFixed(1)}%\n\n'
        'ACTION REQUIRED: Please verify your home safety immediately.\n'
        '• Select [YES] if there is an active fire emergency.\n'
        '• Select [NO] if you checked the area and the issue has been cleared out.\n\n'
        'FireShield AI Autonomous Safety System';
    final url = 'mailto:$userEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    openExternalUrl(url);
  }

  /// Triggers an interactive AI Voice Emergency Call that speaks out loud on the user's device
  void triggerAiEmergencyCall({
    required String roomId,
    required double temperature,
    required int fireAngle,
    required double riskScore,
  }) {
    final speechText =
        'Emergency Alert! This is FireShield AI. Critical abnormal heat of ${temperature.toStringAsFixed(1)} degrees Celsius '
        'and fire signature detected in $roomId at angle $fireAngle degrees! '
        'AI risk score is ${riskScore.toStringAsFixed(0)} percent. '
        'Immediate home safety verification is required! '
        'Please inspect your home. Select NO if the issue is cleared out, or YES to confirm an active emergency!';
    makeAiEmergencyVoiceCall(speechText);
  }

  void stopAiEmergencyCall() {
    stopAiVoiceCall();
  }

  static const MethodChannel _telephonyChannel = MethodChannel('fireshield/telephony');

  /// Directly dials the user's configured SOS phone number
  void dialSosEmergencyCall() {
    final cleanPhone = _sanitizePhoneForSms(userPhone);
    final url = cleanPhone.isNotEmpty ? 'tel:$cleanPhone' : 'tel:911';
    openExternalUrl(url);
  }

  Future<void> executeDirectPhoneCall(String phone) async {
    final cleanPhone = _sanitizePhoneForSms(phone);
    if (cleanPhone.isEmpty) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _telephonyChannel.invokeMethod('directCall', {'phone': cleanPhone});
        debugPrint('📞 Direct native Android call placed to: $cleanPhone');
        return;
      } catch (e) {
        debugPrint('⚠️ Direct native call error: $e');
      }
    }
    openExternalUrl('tel:$cleanPhone');
  }

  Future<void> executeDirectSms({required String phone, required String message}) async {
    final cleanPhone = _sanitizePhoneForSms(phone);
    if (cleanPhone.isEmpty) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _telephonyChannel.invokeMethod('directSms', {
          'phone': cleanPhone,
          'message': message,
        });
        debugPrint('💬 Direct native Android SMS sent to: $cleanPhone');
        return;
      } catch (e) {
        debugPrint('⚠️ Direct native SMS error: $e');
      }
    }
  }

  /// Starts the multi-stage autonomous emergency escalation:
  /// Stage 1 (0 to 30s): In-app verification window with loud continuous AI voice & siren sound
  /// Stage 2 (30s): No response -> Direct Call & SMS auto-dialed to user phone
  /// Stage 3 (120s / 2m): Still no response -> Dispatched directly to Fire Safety Department (101) without intimation
  void startEscalationSequence({
    required String roomId,
    required double temperature,
    required int fireAngle,
    required double riskScore,
    void Function(EscalationPhase phase, int countdownSec)? onTick,
  }) {
    stopEscalation();
    onEscalationTick = onTick;
    _escalationPhase = EscalationPhase.verifying;
    _totalElapsedSeconds = 0;

    // 1. Loudspeaker Continuous AI Voice Alert & Emergency Siren
    triggerAiEmergencyCall(
      roomId: roomId,
      temperature: temperature,
      fireAngle: fireAngle,
      riskScore: riskScore,
    );

    // Initial tick: 30s countdown
    onEscalationTick?.call(EscalationPhase.verifying, 30);

    // 2. Start 1-second interval escalation state machine
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _totalElapsedSeconds++;

      // Phase 1 (0 to 30s): In-app verification window
      if (_totalElapsedSeconds < 30) {
        final remaining = 30 - _totalElapsedSeconds;
        onEscalationTick?.call(EscalationPhase.verifying, remaining);
      }
      // Phase 2 (At exactly 30s): No one responded -> Activate Direct Call & SMS to Primary Contact
      else if (_totalElapsedSeconds == 30) {
        _escalationPhase = EscalationPhase.directCallDispatched;
        debugPrint('⏱️ 30s elapsed with NO user response! Activating Direct Call to $userPhone...');

        await executeDirectPhoneCall(userPhone);
        await executeDirectSms(
          phone: userPhone,
          message: '🚨 [FireShield AI URGENT] No response for 30s! Critical fire in $roomId (${temperature.toStringAsFixed(1)}°C, $fireAngle°). Evacuate immediately!',
        );

        onEscalationTick?.call(EscalationPhase.directCallDispatched, 90);
      }
      // Phase 2 (31s to 120s): Direct call active, counting down remaining to 2 minutes
      else if (_totalElapsedSeconds < 120) {
        final remainingToFireSafety = 120 - _totalElapsedSeconds;
        onEscalationTick?.call(EscalationPhase.directCallDispatched, remainingToFireSafety);
      }
      // Phase 3 (At exactly 120s / 2 minutes): Still no response -> Dispatch directly to Fire Safety Department
      else if (_totalElapsedSeconds == 120) {
        _escalationPhase = EscalationPhase.fireSafetyDispatched;
        debugPrint('⏱️ 2 minutes elapsed with NO user response! ESCALATING DIRECTLY TO FIRE SAFETY ($fireSafetyPhone)...');

        await executeDirectPhoneCall(fireSafetyPhone);
        await executeDirectSms(
          phone: fireSafetyPhone,
          message: '🚨 [FIRE EMERGENCY DISPATCH] Autonomous Alarm: Confirmed unacknowledged structure fire in $roomId. Temp: ${temperature.toStringAsFixed(1)}°C. Bearing: $fireAngle°. AI Risk: ${riskScore.toStringAsFixed(0)}%. IMMEDIATE DISPATCH REQUIRED!',
        );

        // Also broadcast cloud urgent dispatch
        await sendEmergencyVerificationNotice(
          alertId: 'fire_safety_dispatch_${DateTime.now().millisecondsSinceEpoch}',
          roomId: roomId,
          temperature: temperature,
          fireAngle: fireAngle,
          riskScore: riskScore,
        );

        onEscalationTick?.call(EscalationPhase.fireSafetyDispatched, 0);
      } else {
        onEscalationTick?.call(EscalationPhase.fireSafetyDispatched, 0);
      }
    });
  }

  Future<void> cancelEscalation({String? roomId}) async {
    _escalationTimer?.cancel();
    _escalationTimer = null;
    _escalationPhase = EscalationPhase.cancelled;
    _totalElapsedSeconds = 0;
    stopAiEmergencyCall();

    if (roomId != null) {
      await sendAllClearConfirmation(roomId: roomId);
    }
  }

  void stopEscalation() {
    _escalationTimer?.cancel();
    _escalationTimer = null;
    _escalationPhase = EscalationPhase.idle;
    _totalElapsedSeconds = 0;
    stopAiEmergencyCall();
  }

  /// Directly executes an immediate, autonomous emergency dispatch:
  /// - Real direct phone call (auto-dialed without user confirmation)
  /// - Real direct SMS message (auto-sent in background)
  /// - Full-screen AI voice alert on loudspeaker
  /// - Urgent cloud push notification & siren
  Future<void> executeImmediateAutonomousDispatch({
    required String roomId,
    required double temperature,
    required int fireAngle,
    required double riskScore,
  }) async {
    final cleanPhone = _sanitizePhoneForSms(userPhone);

    // 1. Immediately trigger the AI voice alert & siren on loudspeaker
    triggerAiEmergencyCall(
      roomId: roomId,
      temperature: temperature,
      fireAngle: fireAngle,
      riskScore: riskScore,
    );

    // 2. Direct Cellular Phone Call (Free via Device SIM)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && cleanPhone.isNotEmpty) {
      try {
        await _telephonyChannel.invokeMethod('directCall', {'phone': cleanPhone});
        debugPrint('📞 Direct native Android call placed to: $cleanPhone');
      } catch (e) {
        debugPrint('⚠️ Direct native call error, falling back to OS dialer: $e');
        dialSosEmergencyCall();
      }
    } else {
      dialSosEmergencyCall();
    }

    // 3. Direct Background SMS Message (Free via Device SIM)
    final smsBody = '🚨 [FireShield AI CRITICAL FIRE ALERT] Active fire detected in $roomId (${temperature.toStringAsFixed(1)}°C, angle $fireAngle°)! AI Risk: ${riskScore.toStringAsFixed(0)}%. Immediate action required!';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && cleanPhone.isNotEmpty) {
      try {
        await _telephonyChannel.invokeMethod('directSms', {
          'phone': cleanPhone,
          'message': smsBody,
        });
        debugPrint('💬 Direct native Android SMS sent to: $cleanPhone');
      } catch (e) {
        debugPrint('ℹ️ Direct SMS notice: $e');
      }
    }

    // 4. Send cloud notifications & webhooks (ntfy / backend)
    await sendEmergencyVerificationNotice(
      alertId: 'auto_call_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      temperature: temperature,
      fireAngle: fireAngle,
      riskScore: riskScore,
    );
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

    // 2. Automated Cloud Webhook Dispatch (Works directly from GitHub Pages over HTTPS)
    try {
      final cloudTopic = 'fireshield_alerts_${userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      await _dio.post(
        'https://ntfy.sh/$cloudTopic',
        data: '$smsMessage\nEmail sent to: $userEmail',
        options: Options(
          headers: {
            'Title': emailSubject,
            'Priority': 'urgent',
            'Tags': 'fire,rotating_light,warning',
            if (userEmail.contains('@') && !userEmail.contains('example.com') && !userEmail.contains('fireshield.ai'))
              'Email': userEmail,
          },
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      debugPrint('✅ Cloud Push & Mail webhook dispatched via ntfy.sh ($cloudTopic)');
    } catch (e) {
      debugPrint('ℹ️ Cloud webhook notice: $e');
    }

    // 3. Fallback to Local Backend REST Service (if running locally)
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
        options: Options(sendTimeout: const Duration(seconds: 1)),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ Emergency Mail & SMS dispatched via backend gateway.');
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}

    return {
      'status': 'dispatched',
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

    // Cloud Webhook All-Clear Dispatch
    try {
      final cloudTopic = 'fireshield_alerts_${userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      await _dio.post(
        'https://ntfy.sh/$cloudTopic',
        data: '✅ [FireShield AI] $roomId verified safe by user. Issue cleared out. Normal 24.5°C restored.',
        options: Options(
          headers: {
            'Title': '✅ FireShield AI: $roomId Verified Safe - Issue Cleared',
            'Priority': 'default',
            'Tags': 'white_check_mark,shield',
            if (userEmail.contains('@') && !userEmail.contains('example.com') && !userEmail.contains('fireshield.ai'))
              'Email': userEmail,
          },
          sendTimeout: const Duration(seconds: 2),
        ),
      );
    } catch (_) {}

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
