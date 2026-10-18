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
    // Android emulator alias for host machine localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
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
}
