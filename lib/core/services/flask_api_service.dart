import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Reusable HTTP client service communicating with the FireShield AI Flask backend.
/// Kept isolated on client side; NEVER contains private ThingSpeak or server keys.
class FlaskApiService {
  static final FlaskApiService _instance = FlaskApiService._internal();
  factory FlaskApiService() => _instance;

  FlaskApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: defaultBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  late final Dio _dio;

  /// Default backend base URL:
  /// - Web & Desktop: http://127.0.0.1:5000
  /// - Android Emulator: http://10.0.2.2:5000
  static String get defaultBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:5000';
    }
    // Physical Android phones and emulator fallback
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.29.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl.replaceAll(RegExp(r'/+$'), '');
  }

  String get currentBaseUrl => _dio.options.baseUrl;

  /// GET /api/health
  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final response = await _dio.get('/api/health');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getHealth error connecting to ${_dio.options.baseUrl}: $e');
    }
    return null;
  }

  /// GET /api/status
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await _dio.get('/api/status');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getStatus error connecting to ${_dio.options.baseUrl}: $e');
    }
    return null;
  }

  /// GET /api/readings/latest
  Future<Map<String, dynamic>?> getLatestReading({bool forceRefresh = false}) async {
    try {
      final response = await _dio.get(
        '/api/readings/latest',
        queryParameters: forceRefresh ? {'refresh': 'true'} : null,
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getLatestReading error connecting to ${_dio.options.baseUrl}: $e');
    }
    return null;
  }

  /// GET /api/readings
  Future<List<Map<String, dynamic>>> getReadings({int limit = 100, bool forceRefresh = false}) async {
    try {
      final response = await _dio.get(
        '/api/readings',
        queryParameters: {
          'limit': limit,
          if (forceRefresh) 'refresh': 'true',
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final feeds = data['normalized_feeds'];
        if (feeds is List) {
          return feeds.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('FlaskApiService.getReadings error: $e');
    }
    return [];
  }

  /// GET /api/graphs/summary
  Future<Map<String, dynamic>?> getGraphsSummary({int limit = 100}) async {
    try {
      final response = await _dio.get(
        '/api/graphs/summary',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getGraphsSummary error: $e');
    }
    return null;
  }

  /// GET /api/baseline
  Future<Map<String, dynamic>?> getBaseline() async {
    try {
      final response = await _dio.get('/api/baseline');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getBaseline error: $e');
    }
    return null;
  }

  /// GET /api/risk/current - Evaluates current risk state (NORMAL, BASELINE_ANOMALY, EARLY_WARNING, HARDWARE_FIRE_ALERT, SENSOR_OR_DATA_FAULT)
  Future<Map<String, dynamic>?> getCurrentRisk() async {
    try {
      final response = await _dio.get('/api/risk/current');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getCurrentRisk error: $e');
    }
    return null;
  }

  /// GET /api/events - Retrieve persistent event history from SQLite
  Future<List<Map<String, dynamic>>> getEvents({int limit = 20, String? eventType}) async {
    try {
      final response = await _dio.get(
        '/api/events',
        queryParameters: {
          'limit': limit,
          'event_type': ?eventType,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final events = data['events'];
        if (events is List) {
          return events.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('FlaskApiService.getEvents error: $e');
    }
    return [];
  }

  /// GET /api/notifications/status
  Future<Map<String, dynamic>?> getNotificationStatus() async {
    try {
      final response = await _dio.get('/api/notifications/status');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getNotificationStatus error: $e');
    }
    return null;
  }

  /// GET /api/notifications/vapid-public-key
  Future<String?> getVapidPublicKey() async {
    try {
      final response = await _dio.get('/api/notifications/vapid-public-key');
      if (response.statusCode == 200 && response.data is Map) {
        return response.data['public_key'] as String?;
      }
    } catch (e) {
      debugPrint('FlaskApiService.getVapidPublicKey error: $e');
    }
    return null;
  }

  /// POST /api/notifications/subscribe
  Future<bool> subscribeWebPush(Map<String, dynamic> subscriptionJson) async {
    try {
      final response = await _dio.post(
        '/api/notifications/subscribe',
        data: subscriptionJson,
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('FlaskApiService.subscribeWebPush error: $e');
      return false;
    }
  }

  /// POST /api/notifications/test
  Future<bool> sendTestNotification(String channel) async {
    try {
      final response = await _dio.post(
        '/api/notifications/test',
        data: {'channels': [channel]},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return response.data['success'] == true;
      }
    } catch (e) {
      debugPrint('FlaskApiService.sendTestNotification error: $e');
    }
    return false;
  }

  /// GET /api/voice/status - Exotel Voice Call & Provider Configuration
  Future<Map<String, dynamic>?> getVoiceStatus() async {
    try {
      final response = await _dio.get('/api/voice/status');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.getVoiceStatus error: $e');
    }
    return null;
  }

  /// POST /api/voice/test-call - Trigger an authorized test phone call
  Future<Map<String, dynamic>?> triggerTestVoiceCall({String? phone}) async {
    try {
      final response = await _dio.post(
        '/api/voice/test-call',
        data: {
          'phone': ?phone,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('FlaskApiService.triggerTestVoiceCall error: $e');
    }
    return null;
  }
}
