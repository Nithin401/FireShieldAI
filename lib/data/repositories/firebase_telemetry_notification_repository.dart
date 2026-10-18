import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:fireshield_app/domain/models/notification_model.dart';
import 'package:fireshield_app/domain/repositories/notification_repository.dart';

/// Builds the in-app incident feed from ESP telemetry saved in Firebase RTDB.
///
/// This repository intentionally creates alerts only for readings already
/// labelled WARNING, PRE_FIRE, FIRE, or CRITICAL by the detection pipeline. It
/// does not invent an "online" alert and it does not send SMS/WhatsApp.
class FirebaseTelemetryNotificationRepository implements NotificationRepository {
  FirebaseTelemetryNotificationRepository({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;
  final Set<String> _acknowledgedIds = <String>{};
  final Set<String> _knownAlertIds = <String>{};
  final List<NotificationModel> _localAlerts = <NotificationModel>[];

  Query get _readings =>
      _database.ref('devices/ESP1/readings').limitToLast(100);

  @override
  Stream<List<NotificationModel>> getNotifications() {
    return _readings.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return List.unmodifiable(_localAlerts);

      final alerts = <NotificationModel>[];
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        final reading = Map<Object?, Object?>.from(entry.value as Map);
        final alert = _alertFromReading(entry.key.toString(), reading);
        if (alert != null) alerts.add(alert);
      }

      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _knownAlertIds.addAll(alerts.map((alert) => alert.id));
      return List.unmodifiable(<NotificationModel>[..._localAlerts, ...alerts]);
    });
  }

  NotificationModel? _alertFromReading(
    String readingId,
    Map<Object?, Object?> reading,
  ) {
    final state = (reading['label'] ?? reading['fire_state'] ?? 'NORMAL')
        .toString()
        .toUpperCase();
    final isCritical = state == 'FIRE' || state == 'CRITICAL';
    final isWarning = state == 'WARNING' || state == 'PRE_FIRE';
    if (!isCritical && !isWarning) return null;

    final deviceId = (reading['device_id'] ?? 'ESP1').toString();
    final room = (reading['room_id'] ?? reading['room'] ?? 'Unassigned zone')
        .toString();
    final temperature = _asDouble(
      reading['temperature_c'] ?? reading['temperature'] ?? reading['tempC'],
    );
    final gasRaw = _asInt(reading['gas_raw']);
    final angle = _asInt(reading['servo_angle']) ?? 90;
    final risk = isCritical ? 98.0 : 45.0;
    final title = isCritical ? 'Fire detected: $room' : 'Elevated fire risk: $room';
    final details = <String>[
      if (temperature != null) '${temperature.toStringAsFixed(1)}°C',
      if (gasRaw != null) 'gas $gasRaw',
      'bearing $angle°',
    ].join(' • ');

    return NotificationModel(
      id: 'telemetry_$readingId',
      title: title,
      message: '$state telemetry from $deviceId${details.isEmpty ? '' : ': $details'}',
      timestamp: _timestamp(reading['timestamp']),
      isRead: _acknowledgedIds.contains('telemetry_$readingId'),
      severity: isCritical ? 'critical' : 'warning',
      deviceId: deviceId,
      roomId: room,
      fireState: state,
      riskScore: risk,
      fireAngle: angle,
    );
  }

  DateTime _timestamp(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true).toLocal();
    }
    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

  int? _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  @override
  void addLocalAlert(NotificationModel notification) {
    _localAlerts.insert(0, notification);
  }

  @override
  Future<void> acknowledgeNotification(String id) async {
    _acknowledgedIds.add(id);
  }

  @override
  Future<void> markAllAsRead() async {
    _acknowledgedIds.addAll(_knownAlertIds);
    _acknowledgedIds.addAll(_localAlerts.map((alert) => alert.id));
  }
}
