import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';
import 'package:fireshield_app/presentation/features/device/widgets/device_list_tile.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
      ),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return Center(
              child: Text(
                'No devices found.\nAdd one to get started.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return DeviceListTile(
                device: device,
                onTap: () {
                  context.push('/devices/${device.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/devices/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
