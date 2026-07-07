// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MockNotifications)
final mockNotificationsProvider = MockNotificationsProvider._();

final class MockNotificationsProvider
    extends $NotifierProvider<MockNotifications, List<NotificationModel>> {
  MockNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mockNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mockNotificationsHash();

  @$internal
  @override
  MockNotifications create() => MockNotifications();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<NotificationModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<NotificationModel>>(value),
    );
  }
}

String _$mockNotificationsHash() => r'012561dc0340c76904ddc7c163c7d67fd9833142';

abstract class _$MockNotifications extends $Notifier<List<NotificationModel>> {
  List<NotificationModel> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<NotificationModel>, List<NotificationModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<NotificationModel>, List<NotificationModel>>,
              List<NotificationModel>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
