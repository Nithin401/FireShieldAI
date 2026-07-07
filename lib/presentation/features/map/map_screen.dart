import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? mapController;

  // Initial camera position (San Francisco for mock data)
  final LatLng _center = const LatLng(37.7749, -122.4194);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
      ),
      body: devicesAsync.when(
        data: (devices) {
          // Create markers for devices
          final Set<Marker> markers = devices.map((device) {
            double hue = BitmapDescriptor.hueGreen;
            if (!device.isOnline) {
              hue = BitmapDescriptor.hueRed;
            } else if (device.batteryLevel < 20) {
              hue = BitmapDescriptor.hueOrange;
            }

            return Marker(
              markerId: MarkerId(device.id),
              position: LatLng(device.latitude, device.longitude),
              infoWindow: InfoWindow(
                title: device.name,
                snippet: 'Status: ${device.isOnline ? 'Online' : 'Offline'}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            );
          }).toSet();

          // Add Mock Fire Station and Hospital Markers
          markers.addAll([
            Marker(
              markerId: const MarkerId('fire_station_1'),
              position: const LatLng(37.7800, -122.4200),
              infoWindow: const InfoWindow(
                title: 'SF Fire Department Station 1',
                snippet: 'Emergency Response Unit',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
            Marker(
              markerId: const MarkerId('hospital_1'),
              position: const LatLng(37.7700, -122.4300),
              infoWindow: const InfoWindow(
                title: 'General Hospital',
                snippet: 'Emergency Room',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
            ),
          ]);

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 13.0,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _center,
                          zoom: 14.0,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
              // Legend overlay
              Positioned(
                top: 16,
                left: 16,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(Colors.green, 'Online Device'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.orange, 'Warning/Low Battery'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.red, 'Offline/Alert'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.blue, 'Fire Station'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.purple, 'Hospital'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
