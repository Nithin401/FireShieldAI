import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';
import 'package:fireshield_app/domain/models/device_model.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';
import 'package:fireshield_app/core/services/emergency_dispatch_service.dart';
import 'package:fireshield_app/core/services/web_notification_helper.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  // Default coordinate (fallback if GPS disabled: Hyderabad / Tech Hub)
  LatLng _currentPosition = const LatLng(17.3850, 78.4867);
  bool _isLocating = false;
  bool _hasCustomGps = false;

  // Simulated Fire state for testing & demonstration
  bool _isSimulatedFireActive = false;
  LatLng? _activeFirePosition;
  final double _simulatedTemp = 84.5;
  final int _simulatedSmoke = 620;
  final int _simulatedAngle = 48;

  // Selected Station for detailed route inspect
  Map<String, dynamic>? _selectedHelpStation;

  // Animation controller for pulsing radar ripple
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _determinePosition();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service disabled, keeping fallback center');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newCoord = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentPosition = newCoord;
          _hasCustomGps = true;
          if (_isSimulatedFireActive) {
            _activeFirePosition = LatLng(newCoord.latitude + 0.0018, newCoord.longitude + 0.0015);
          }
        });
        _mapController.move(newCoord, 15.0);
      }
    } catch (e) {
      debugPrint("Error fetching GPS position: $e");
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _toggleSimulatedFire() {
    setState(() {
      _isSimulatedFireActive = !_isSimulatedFireActive;
      if (_isSimulatedFireActive) {
        _activeFirePosition = LatLng(
          _currentPosition.latitude + 0.0018,
          _currentPosition.longitude + 0.0015,
        );
        _mapController.move(_activeFirePosition!, 15.5);
      } else {
        _activeFirePosition = null;
      }
    });

    if (_isSimulatedFireActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🔥 Fire Alert Activated at ${_activeFirePosition!.latitude.toStringAsFixed(4)}, ${_activeFirePosition!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'DISPATCH',
            textColor: Colors.white,
            onPressed: _openEmergencyDispatchModal,
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getEmergencyStations(LatLng center) {
    return [
      {
        'id': 'fire_dept_1',
        'type': 'FIRE_STATION',
        'name': 'Central Fire & Rescue Station #1',
        'shortName': 'Fire Station',
        'phone': '101',
        'coord': LatLng(center.latitude + 0.0065, center.longitude - 0.0052),
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFEF4444),
      },
      {
        'id': 'police_dept_1',
        'type': 'POLICE_HQ',
        'name': 'City Emergency Police Division',
        'shortName': 'Police Dispatch',
        'phone': '100',
        'coord': LatLng(center.latitude - 0.0048, center.longitude + 0.0068),
        'icon': Icons.local_police,
        'color': const Color(0xFF38BDF8),
      },
      {
        'id': 'hospital_1',
        'type': 'TRAUMA_HOSPITAL',
        'name': 'Apex General Trauma & Burn Center',
        'shortName': 'Emergency Trauma',
        'phone': '108',
        'coord': LatLng(center.latitude - 0.0072, center.longitude - 0.0045),
        'icon': Icons.medical_services,
        'color': const Color(0xFF10B981),
      },
    ];
  }

  void _openEmergencyDispatchModal() {
    final fireCoord = _activeFirePosition ?? _currentPosition;
    final stations = _getEmergencyStations(_currentPosition);
    final nearestFireStation = stations.firstWhere((s) => s['type'] == 'FIRE_STATION');
    final distMeters = _distance.as(LengthUnit.Meter, fireCoord, nearestFireStation['coord'] as LatLng);
    final etaMin = (distMeters / 600.0).clamp(1.0, 15.0).toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.6)),
                  ),
                  child: const Icon(Icons.emergency_share, color: AppColors.error, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispatch Live Fire Coordinates',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Direct routing to nearest emergency services',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Pin & Coordinates Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFFEF4444), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Precise Fire Point of Origin',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                            text: '${fireCoord.latitude.toStringAsFixed(6)}, ${fireCoord.longitude.toStringAsFixed(6)}',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coordinates copied to clipboard!'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.copy, color: Color(0xFF38BDF8), size: 14),
                            SizedBox(width: 4),
                            Text('Copy', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${fireCoord.latitude.toStringAsFixed(6)}° N, ${fireCoord.longitude.toStringAsFixed(6)}° E',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildMiniBadge(Icons.thermostat, '${_simulatedTemp.toStringAsFixed(1)}°C Temp', const Color(0xFFEF4444)),
                      _buildMiniBadge(Icons.grain, '$_simulatedSmoke PPM Smoke', const Color(0xFFA855F7)),
                      _buildMiniBadge(Icons.radar, '$_simulatedAngle° Bearing Azimuth', const Color(0xFFF59E0B)),
                      _buildMiniBadge(Icons.timer_outlined, '~$etaMin min Response ETA', const Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Target Station Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fire_truck, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nearestFireStation['name'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'Direct Distance: ${(distMeters / 1000.0).toStringAsFixed(2)} km  •  Emergency Hotline: 101',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Dispatch Action Buttons
            Row(
              children: [
                // Direct Phone Call to Fire Department
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call 101 Fire Dept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      EmergencyDispatchService().executeDirectPhoneCall(nearestFireStation['phone'] as String);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Direct SMS Dispatch with Coordinates
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.sms, size: 18),
                    label: const Text('Transmit SOS SMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      final message = '🚨 EMERGENCY FIRE ALERT! '
                          'Critical fire detected at GPS Coordinates: ${fireCoord.latitude.toStringAsFixed(6)}, ${fireCoord.longitude.toStringAsFixed(6)}. '
                          'Temp: ${_simulatedTemp.toStringAsFixed(1)}°C, Smoke: $_simulatedSmoke PPM, Bearing: $_simulatedAngle°. '
                          'Map Link: https://maps.google.com/?q=${fireCoord.latitude},${fireCoord.longitude}';
                      EmergencyDispatchService().executeDirectSms(
                        phone: nearestFireStation['phone'] as String,
                        message: message,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Navigation and WhatsApp Broadcast Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Navigate in Maps', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      final url = 'https://www.google.com/maps/dir/?api=1&destination=${fireCoord.latitude},${fireCoord.longitude}';
                      openExternalUrl(url);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF22C55E),
                      side: const BorderSide(color: Color(0xFF22C55E)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('WhatsApp Dispatch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      final text = '🚨 *FireShield AI: Live Fire Coordinates Dispatch*\n\n'
                          '🔥 *Active Fire Confirmed!*\n'
                          '• Coordinates: `${fireCoord.latitude.toStringAsFixed(6)}, ${fireCoord.longitude.toStringAsFixed(6)}`\n'
                          '• Temperature: *${_simulatedTemp.toStringAsFixed(1)}°C*\n'
                          '• Smoke Gas: *$_simulatedSmoke PPM*\n'
                          '• Threat Azimuth: *$_simulatedAngle°*\n\n'
                          '📍 *Google Maps Pin:* https://maps.google.com/?q=${fireCoord.latitude},${fireCoord.longitude}\n\n'
                          'Immediate Fire Engine Dispatch Requested!';
                      final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
                      openExternalUrl(url);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final stations = _getEmergencyStations(_currentPosition);

    // Identify if any real hardware node reports active fire
    final realFireDevice = devicesAsync.asData?.value.cast<DeviceModel?>().firstWhere(
      (d) => d != null && d.fireState == 'FIRE',
      orElse: () => null,
    );

    final LatLng? effectiveFireCoord = realFireDevice != null
        ? LatLng(realFireDevice.latitude, realFireDevice.longitude)
        : _activeFirePosition;

    final bool isFireActive = effectiveFireCoord != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            const Icon(Icons.map_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Live Geolocation & Fire Dispatch', style: TextStyle(fontSize: 16)),
            const Spacer(),
            if (isFireActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: AppColors.error, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'FIRE ACTIVE',
                      style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Real Interactive OpenStreetMap Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fireshield.fireshield_app',
              ),

              // Threat Perimeter Circle & Radar Ripple if Fire is Active
              if (isFireActive) ...[
                CircleLayer(
                  circles: [
                    // Outer danger perimeter (150m)
                    CircleMarker(
                      point: effectiveFireCoord,
                      radius: 80,
                      useRadiusInMeter: false,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderColor: const Color(0xFFEF4444).withValues(alpha: 0.8),
                      borderStrokeWidth: 2,
                    ),
                    // Inner thermal ignition core
                    CircleMarker(
                      point: effectiveFireCoord,
                      radius: 35,
                      useRadiusInMeter: false,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      borderColor: const Color(0xFFF97316),
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),
                // Route/Bearing line from User/Hub to Fire
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_currentPosition, effectiveFireCoord],
                      strokeWidth: 3,
                      color: const Color(0xFFEF4444),
                      pattern: StrokePattern.dashed(segments: const [8, 4]),
                    ),
                  ],
                ),
              ],

              // Route Line to Selected Help Station
              if (_selectedHelpStation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        effectiveFireCoord ?? _currentPosition,
                        _selectedHelpStation!['coord'] as LatLng,
                      ],
                      strokeWidth: 4,
                      color: _selectedHelpStation!['color'] as Color,
                    ),
                  ],
                ),

              // Markers Layer: User Hub, Fire Threat, Emergency Stations
              MarkerLayer(
                markers: [
                  // 1. Current Hub / Facility Marker
                  Marker(
                    point: _currentPosition,
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.home, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),

                  // 2. Fire Threat Marker (if active)
                  if (isFireActive)
                    Marker(
                      point: effectiveFireCoord,
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.25);
                          return Transform.scale(
                            scale: scale,
                            child: GestureDetector(
                              onTap: _openEmergencyDispatchModal,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // 3. Emergency Response Stations (Fire Station, Police HQ, Trauma Center)
                  ...stations.map((station) {
                    final isSelected = _selectedHelpStation?['id'] == station['id'];
                    final color = station['color'] as Color;
                    final icon = station['icon'] as IconData;

                    return Marker(
                      point: station['coord'] as LatLng,
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedHelpStation = isSelected ? null : station;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white70,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: isSelected ? 12 : 6,
                                spreadRadius: isSelected ? 2 : 1,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Top Status Badge Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFireActive ? AppColors.error : const Color(0xFF334155),
                  width: isFireActive ? 2 : 1,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isFireActive ? AppColors.error : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFireActive
                              ? '🔥 Fire Origin: ${effectiveFireCoord.latitude.toStringAsFixed(4)}, ${effectiveFireCoord.longitude.toStringAsFixed(4)}'
                              : (_hasCustomGps ? '📍 GPS Locked: Real-Time Precision' : '📍 Protected Facility Hub'),
                          style: TextStyle(
                            color: isFireActive ? const Color(0xFFEF4444) : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isFireActive
                              ? 'Tap "Dispatch" below to route 101 Fire Department'
                              : 'Tap fire icon or trigger simulation to test dispatch',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isFireActive)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openEmergencyDispatchModal,
                      child: const Text('DISPATCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ),

          // 3. Floating Action Controls (GPS Re-center, Fire Simulate Toggle, Dispatch)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Simulate Fire Trigger Button
                FloatingActionButton.small(
                  heroTag: 'simulate_fire',
                  backgroundColor: _isSimulatedFireActive ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  tooltip: _isSimulatedFireActive ? 'Clear Simulated Fire' : 'Test Fire Geolocation',
                  onPressed: _toggleSimulatedFire,
                  child: Icon(_isSimulatedFireActive ? Icons.fire_extinguisher : Icons.local_fire_department),
                ),
                const SizedBox(height: 10),

                // Re-center on My GPS
                FloatingActionButton.small(
                  heroTag: 'recenter_gps',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFF38BDF8),
                  tooltip: 'Locate Me',
                  onPressed: _isLocating ? null : _determinePosition,
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),

                // Dispatch Coordinates FAB
                FloatingActionButton.extended(
                  heroTag: 'dispatch_fab',
                  backgroundColor: isFireActive ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.emergency_share, size: 20),
                  label: Text(
                    isFireActive ? 'Dispatch to 101' : 'Send Help Data',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _openEmergencyDispatchModal,
                ),
              ],
            ),
          ),

          // 4. Selected Station Quick Info Card (if tapped on a station marker)
          if (_selectedHelpStation != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 190,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _selectedHelpStation!['color'] as Color, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedHelpStation!['icon'] as IconData,
                          color: _selectedHelpStation!['color'] as Color,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedHelpStation!['shortName'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedHelpStation = null),
                          child: const Icon(Icons.close, color: Colors.white54, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dist: ${(_distance.as(LengthUnit.Meter, _currentPosition, _selectedHelpStation!['coord'] as LatLng) / 1000.0).toStringAsFixed(2)} km',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedHelpStation!['color'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.phone, size: 12),
                        label: Text(
                          'Call ${_selectedHelpStation!['phone']}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          EmergencyDispatchService().executeDirectPhoneCall(
                            _selectedHelpStation!['phone'] as String,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
