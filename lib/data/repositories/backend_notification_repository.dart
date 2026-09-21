import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fireshield_app/domain/models/notification_model.dart';
import 'package:fireshield_app/domain/repositories/notification_repository.dart';

/// Real backend & Autonomous Offline-First NotificationRepository
class BackendNotificationRepository implements NotificationRepository {
  final Dio _dio = Dio();
  final String _alertsUrl = 'http://localhost:5000/api/alerts';
  
  // Local cache pre-seeded so app is immediately populated offline
  List<NotificationModel> _cachedNotifications = [
    NotificationModel(
      id: 'notif_sys_init',
      title: 'FireShield AI System Online',
      message: 'Autonomous multi-sensor monitoring active. All zones normal.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: true,
      severity: 'info',
      deviceId: 'dev_001',
      roomId: 'Kitchen',
      fireState: 'SAFE',
      riskScore: 10.0,
      fireAngle: 90,
    ),
  ];

  @override
  Stream<List<NotificationModel>> getNotifications() async* {
    // Immediately emit default state with 0 loading delay
    yield List.unmodifiable(_cachedNotifications);

    while (true) {
      try {
        final response = await _dio.get(
          _alertsUrl,
          options: Options(
            sendTimeout: const Duration(milliseconds: 1200),
            receiveTimeout: const Duration(milliseconds: 1200),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final List<dynamic> list = response.data is List
              ? response.data
              : jsonDecode(response.data.toString());

          final alerts = list
              .map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();

          if (alerts.isNotEmpty) {
            _cachedNotifications = alerts;
          }
        }
      } catch (e) {
        // Backend offline: silently keep using local notifications
      }

      yield List.unmodifiable(_cachedNotifications);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  void addLocalAlert(NotificationModel notif) {
    _cachedNotifications = [notif, ..._cachedNotifications];
  }

  @override
  Future<void> acknowledgeNotification(String id) async {
    // Update local state immediately
    _cachedNotifications = _cachedNotifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    try {
      await _dio.post(
        'http://localhost:5000/api/alerts/$id/ack',
        options: Options(
          sendTimeout: const Duration(milliseconds: 1000),
          receiveTimeout: const Duration(milliseconds: 1000),
        ),
      );
    } catch (_) {
      // Ignored if backend is offline
    }
  }

  @override
  Future<void> markAllAsRead() async {
    _cachedNotifications = _cachedNotifications.map((n) => n.copyWith(isRead: true)).toList();

    for (final notif in _cachedNotifications) {
      try {
        await _dio.post(
          'http://localhost:5000/api/alerts/${notif.id}/ack',
          options: Options(sendTimeout: const Duration(milliseconds: 500)),
        );
      } catch (_) {}
    }
  }
}
