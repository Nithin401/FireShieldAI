import 'package:fireshield_app/domain/models/notification_model.dart';

abstract class NotificationRepository {
  /// Stream continuous updates of system & AI risk notifications
  Stream<List<NotificationModel>> getNotifications();

  /// Acknowledge an alert on the server/database
  Future<void> acknowledgeNotification(String id);

  /// Mark all notifications as acknowledged/read
  Future<void> markAllAsRead();

  /// Add a local notification (e.g. from in-app simulation or offline edge events)
  void addLocalAlert(NotificationModel notif);
}
