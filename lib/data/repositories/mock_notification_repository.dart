import 'dart:async';
import 'package:fireshield_app/domain/models/notification_model.dart';
import 'package:fireshield_app/domain/repositories/notification_repository.dart';

/// Mock implementation of NotificationRepository for offline development & testing
class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _mockData = [
    NotificationModel(
      id: 'notif_1',
      title: 'Smoke Detected',
      message: 'Elevated smoke levels detected in Kitchen Smoke Detector.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      severity: 'critical',
      deviceId: 'dev_001',
      roomId: 'Kitchen',
      fireState: 'FIRE',
      riskScore: 94.5,
      fireAngle: 90,
    ),
    NotificationModel(
      id: 'notif_2',
      title: 'Low Battery',
      message: 'Lobby Fire Alarm battery is below 20%. Please replace soon.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      severity: 'warning',
      deviceId: 'dev_003',
      roomId: 'Lobby',
      fireState: 'SAFE',
      riskScore: 12.0,
      fireAngle: 0,
    ),
    NotificationModel(
      id: 'notif_3',
      title: 'System Update',
      message: 'Firmware v2.0-HybridAI successfully installed on Kitchen Smoke Detector.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      severity: 'info',
      deviceId: 'dev_001',
      roomId: 'Kitchen',
      fireState: 'SAFE',
      riskScore: 5.0,
      fireAngle: 0,
    ),
  ];

  @override
  Stream<List<NotificationModel>> getNotifications() async* {
    yield List.unmodifiable(_mockData);
  }

  @override
  Future<void> acknowledgeNotification(String id) async {
    final index = _mockData.indexWhere((n) => n.id == id);
    if (index != -1) {
      _mockData[index] = _mockData[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _mockData.length; i++) {
      _mockData[i] = _mockData[i].copyWith(isRead: true);
    }
  }

  @override
  void addLocalAlert(NotificationModel notif) {
    _mockData.insert(0, notif);
  }
}
