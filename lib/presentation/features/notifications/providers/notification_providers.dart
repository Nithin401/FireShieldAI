import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fireshield_app/domain/models/notification_model.dart';

part 'notification_providers.g.dart';

@riverpod
class MockNotifications extends _$MockNotifications {
  @override
  List<NotificationModel> build() {
    return [
      NotificationModel(
        id: 'notif_1',
        title: 'Smoke Detected',
        message: 'Elevated smoke levels detected in Kitchen Smoke Detector.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        severity: 'critical',
      ),
      NotificationModel(
        id: 'notif_2',
        title: 'Low Battery',
        message: 'Lobby Fire Alarm battery is below 20%. Please replace soon.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        severity: 'warning',
      ),
      NotificationModel(
        id: 'notif_3',
        title: 'System Update',
        message: 'Firmware v1.2.4 successfully installed on Kitchen Smoke Detector.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        severity: 'info',
      ),
    ];
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}
