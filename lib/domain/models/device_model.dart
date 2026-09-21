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

  // Sensor & Telemetry Fields
  final double ambientTemperature; // DHT22
  final double ambientHumidity;    // DHT22
  final double irTemperature;     // MLX90614
  final double preciseTemperature; // DS18B20
  final bool hasThermalAbnormality; // FLIR Lepton

  // Real-Time Fire & Angle Telemetry
  final int flameRaw;
  final int gasRaw;
  final int smokeRaw;
  final int fireAngle;
  final double riskScore;
  final String fireState;      // SAFE, WARNING, HIGH_RISK, FIRE
  final String responseStatus; // IDLE, AIMING, ACTIVE, CLEARED

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
    this.ambientTemperature = 25.0,
    this.ambientHumidity = 50.0,
    this.irTemperature = 25.0,
    this.preciseTemperature = 25.0,
    this.hasThermalAbnormality = false,
    this.flameRaw = 850,
    this.gasRaw = 120,
    this.smokeRaw = 110,
    this.fireAngle = 90,
    this.riskScore = 0.0,
    this.fireState = 'SAFE',
    this.responseStatus = 'IDLE',
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String? ?? 'dev_001',
      name: json['name'] as String? ?? 'Fire Detection Node',
      room: json['room'] as String? ?? 'General Room',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -122.4194,
      firmwareVersion: json['firmwareVersion'] as String? ?? 'v1.0',
      isOnline: json['isOnline'] as bool? ?? true,
      batteryLevel: (json['batteryLevel'] as num?)?.toInt() ?? 100,
      wifiSignalStrength: (json['wifiSignalStrength'] as num?)?.toInt() ?? 90,
      lastSync: json['lastSync'] != null 
          ? DateTime.tryParse(json['lastSync'] as String) ?? DateTime.now()
          : DateTime.now(),
      ambientTemperature: (json['ambientTemperature'] as num?)?.toDouble() ?? (json['tempC'] as num?)?.toDouble() ?? 25.0,
      ambientHumidity: (json['ambientHumidity'] as num?)?.toDouble() ?? (json['humidity'] as num?)?.toDouble() ?? 50.0,
      irTemperature: (json['irTemperature'] as num?)?.toDouble() ?? 25.0,
      preciseTemperature: (json['preciseTemperature'] as num?)?.toDouble() ?? 25.0,
      hasThermalAbnormality: json['hasThermalAbnormality'] as bool? ?? false,
      flameRaw: (json['flameRaw'] as num?)?.toInt() ?? 850,
      gasRaw: (json['gasRaw'] as num?)?.toInt() ?? (json['gas'] as num?)?.toInt() ?? 120,
      smokeRaw: (json['smokeRaw'] as num?)?.toInt() ?? (json['smoke'] as num?)?.toInt() ?? 110,
      fireAngle: (json['fireAngle'] as num?)?.toInt() ?? 90,
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
      fireState: json['fireState'] as String? ?? 'SAFE',
      responseStatus: json['responseStatus'] as String? ?? 'IDLE',
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
      'ambientTemperature': ambientTemperature,
      'ambientHumidity': ambientHumidity,
      'irTemperature': irTemperature,
      'preciseTemperature': preciseTemperature,
      'hasThermalAbnormality': hasThermalAbnormality,
      'flameRaw': flameRaw,
      'gasRaw': gasRaw,
      'smokeRaw': smokeRaw,
      'fireAngle': fireAngle,
      'riskScore': riskScore,
      'fireState': fireState,
      'responseStatus': responseStatus,
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
    double? ambientTemperature,
    double? ambientHumidity,
    double? irTemperature,
    double? preciseTemperature,
    bool? hasThermalAbnormality,
    int? flameRaw,
    int? gasRaw,
    int? smokeRaw,
    int? fireAngle,
    double? riskScore,
    String? fireState,
    String? responseStatus,
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
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      ambientHumidity: ambientHumidity ?? this.ambientHumidity,
      irTemperature: irTemperature ?? this.irTemperature,
      preciseTemperature: preciseTemperature ?? this.preciseTemperature,
      hasThermalAbnormality: hasThermalAbnormality ?? this.hasThermalAbnormality,
      flameRaw: flameRaw ?? this.flameRaw,
      gasRaw: gasRaw ?? this.gasRaw,
      smokeRaw: smokeRaw ?? this.smokeRaw,
      fireAngle: fireAngle ?? this.fireAngle,
      riskScore: riskScore ?? this.riskScore,
      fireState: fireState ?? this.fireState,
      responseStatus: responseStatus ?? this.responseStatus,
    );
  }
}
