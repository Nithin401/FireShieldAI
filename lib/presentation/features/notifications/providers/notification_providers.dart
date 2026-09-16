import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireshield_app/domain/models/notification_model.dart';
import 'package:fireshield_app/domain/repositories/notification_repository.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';

export 'package:fireshield_app/presentation/providers/repository_providers.dart'
    show notificationsStreamProvider, notificationRepositoryProvider;

/// State notifier managing live FireShield AI alerts and acknowledgement states
class NotificationNotifier extends Notifier<List<NotificationModel>> {
  late final NotificationRepository _repository;

  @override
  List<NotificationModel> build() {
    _repository = ref.watch(notificationRepositoryProvider);
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsStreamProvider, (previous, next) {
      next.whenData((data) {
        state = data;
      });
    });
    return [];
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _repository.markAllAsRead();
  }

  Future<void> acknowledge(String id) async {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    await _repository.acknowledgeNotification(id);
  }
}

/// Provider consumed by NotificationsScreen and Dashboard
final mockNotificationsProvider =
    NotifierProvider<NotificationNotifier, List<NotificationModel>>(NotificationNotifier.new);


