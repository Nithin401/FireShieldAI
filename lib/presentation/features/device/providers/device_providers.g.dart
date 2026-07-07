// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MockDevices)
final mockDevicesProvider = MockDevicesProvider._();

final class MockDevicesProvider
    extends $NotifierProvider<MockDevices, List<DeviceModel>> {
  MockDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mockDevicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mockDevicesHash();

  @$internal
  @override
  MockDevices create() => MockDevices();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DeviceModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DeviceModel>>(value),
    );
  }
}

String _$mockDevicesHash() => r'bb93b09100608e0d4632f013c79e412afa03144b';

abstract class _$MockDevices extends $Notifier<List<DeviceModel>> {
  List<DeviceModel> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<DeviceModel>, List<DeviceModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<DeviceModel>, List<DeviceModel>>,
              List<DeviceModel>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
