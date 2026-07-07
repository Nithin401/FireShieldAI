class DeviceModel {
  final String id;
  final String name;
  final String room;
  final double latitude;
  final double longitude;
  final String firmwareVersion;
  final bool isOnline;
  final int batteryLevel;
  final int wifiSignalStrength;
  final DateTime lastSync;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.room,
    required this.latitude,
    required this.longitude,
    required this.firmwareVersion,
    required this.isOnline,
    required this.batteryLevel,
    required this.wifiSignalStrength,
    required this.lastSync,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      room: json['room'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      firmwareVersion: json['firmwareVersion'] as String,
      isOnline: json['isOnline'] as bool,
      batteryLevel: json['batteryLevel'] as int,
      wifiSignalStrength: json['wifiSignalStrength'] as int,
      lastSync: DateTime.parse(json['lastSync'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'room': room,
      'latitude': latitude,
      'longitude': longitude,
      'firmwareVersion': firmwareVersion,
      'isOnline': isOnline,
      'batteryLevel': batteryLevel,
      'wifiSignalStrength': wifiSignalStrength,
      'lastSync': lastSync.toIso8601String(),
    };
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? room,
    double? latitude,
    double? longitude,
    String? firmwareVersion,
    bool? isOnline,
    int? batteryLevel,
    int? wifiSignalStrength,
    DateTime? lastSync,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      wifiSignalStrength: wifiSignalStrength ?? this.wifiSignalStrength,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
