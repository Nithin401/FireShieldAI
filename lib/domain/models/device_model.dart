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
  final double ambientTemperature; // BME280 / DHT22
  final double ambientHumidity;    // BME280 / DHT22
  final double pressure;           // BME280 (hPa)
  final double irTemperature;     // MLX90614
  final double preciseTemperature; // DS18B20
  final bool hasThermalAbnormality; // FLIR Lepton

  // Real-Time Fire & Angle Telemetry
  final int flameRaw;              // ADS1115 A0 (0-32767)
  final double flameVoltage;       // Calculated V
  final int gasRaw;                // ADS1115 A1 (0-32767)
  final double gasVoltage;         // Calculated V
  final int smokeRaw;
  final int fireAngle;             // Servo Azimuth 0-180
  final double riskScore;
  final String fireState;          // NORMAL, WARNING, PRE_FIRE, FIRE, CRITICAL
  final String responseStatus;     // IDLE, AIMING, ACTIVE, CLEARED
  final bool sensorsValid;
  final int wifiRssi;              // dBm

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
    this.pressure = 1013.25,
    this.irTemperature = 25.0,
    this.preciseTemperature = 25.0,
    this.hasThermalAbnormality = false,
    this.flameRaw = 14500,
    this.flameVoltage = 3.0,
    this.gasRaw = 1400,
    this.gasVoltage = 0.35,
    this.smokeRaw = 110,
    this.fireAngle = 90,
    this.riskScore = 0.0,
    this.fireState = 'NORMAL',
    this.responseStatus = 'IDLE',
    this.sensorsValid = true,
    this.wifiRssi = -55,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String? ?? 'ESP1',
      name: json['name'] as String? ?? 'ESP1 Fire Node',
      room: json['room'] as String? ?? json['room_id'] as String? ?? 'General Room',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -122.4194,
      firmwareVersion: json['firmwareVersion'] as String? ?? 'v2.2-RTDB',
      isOnline: json['isOnline'] as bool? ?? true,
      batteryLevel: (json['batteryLevel'] as num?)?.toInt() ?? 100,
      wifiSignalStrength: (json['wifiSignalStrength'] as num?)?.toInt() ?? 90,
      lastSync: json['lastSync'] != null 
          ? DateTime.tryParse(json['lastSync'] as String) ?? DateTime.now()
          : DateTime.now(),
      ambientTemperature: (json['ambientTemperature'] as num?)?.toDouble() ??
          (json['temperature'] as num?)?.toDouble() ??
          (json['tempC'] as num?)?.toDouble() ?? 25.0,
      ambientHumidity: (json['ambientHumidity'] as num?)?.toDouble() ??
          (json['humidity'] as num?)?.toDouble() ?? 50.0,
      pressure: (json['pressure'] as num?)?.toDouble() ?? 1013.25,
      irTemperature: (json['irTemperature'] as num?)?.toDouble() ?? 25.0,
      preciseTemperature: (json['preciseTemperature'] as num?)?.toDouble() ?? 25.0,
      hasThermalAbnormality: json['hasThermalAbnormality'] as bool? ?? false,
      flameRaw: (json['flameRaw'] as num?)?.toInt() ?? (json['flame_raw'] as num?)?.toInt() ?? 14500,
      flameVoltage: (json['flameVoltage'] as num?)?.toDouble() ?? (json['flame_voltage'] as num?)?.toDouble() ?? 3.0,
      gasRaw: (json['gasRaw'] as num?)?.toInt() ?? (json['gas_raw'] as num?)?.toInt() ?? 1400,
      gasVoltage: (json['gasVoltage'] as num?)?.toDouble() ?? (json['gas_voltage'] as num?)?.toDouble() ?? 0.35,
      smokeRaw: (json['smokeRaw'] as num?)?.toInt() ?? (json['smoke'] as num?)?.toInt() ?? 110,
      fireAngle: (json['fireAngle'] as num?)?.toInt() ?? (json['servo_angle'] as num?)?.toInt() ?? 90,
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
      fireState: json['fireState'] as String? ?? json['fire_state'] as String? ?? 'NORMAL',
      responseStatus: json['responseStatus'] as String? ?? 'IDLE',
      sensorsValid: json['sensorsValid'] as bool? ?? json['sensors_valid'] as bool? ?? true,
      wifiRssi: (json['wifiRssi'] as num?)?.toInt() ?? (json['wifi_rssi'] as num?)?.toInt() ?? -55,
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
      'pressure': pressure,
      'irTemperature': irTemperature,
      'preciseTemperature': preciseTemperature,
      'hasThermalAbnormality': hasThermalAbnormality,
      'flameRaw': flameRaw,
      'flameVoltage': flameVoltage,
      'gasRaw': gasRaw,
      'gasVoltage': gasVoltage,
      'smokeRaw': smokeRaw,
      'fireAngle': fireAngle,
      'riskScore': riskScore,
      'fireState': fireState,
      'responseStatus': responseStatus,
      'sensorsValid': sensorsValid,
      'wifiRssi': wifiRssi,
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
    double? pressure,
    double? irTemperature,
    double? preciseTemperature,
    bool? hasThermalAbnormality,
    int? flameRaw,
    double? flameVoltage,
    int? gasRaw,
    double? gasVoltage,
    int? smokeRaw,
    int? fireAngle,
    double? riskScore,
    String? fireState,
    String? responseStatus,
    bool? sensorsValid,
    int? wifiRssi,
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
      pressure: pressure ?? this.pressure,
      irTemperature: irTemperature ?? this.irTemperature,
      preciseTemperature: preciseTemperature ?? this.preciseTemperature,
      hasThermalAbnormality: hasThermalAbnormality ?? this.hasThermalAbnormality,
      flameRaw: flameRaw ?? this.flameRaw,
      flameVoltage: flameVoltage ?? this.flameVoltage,
      gasRaw: gasRaw ?? this.gasRaw,
      gasVoltage: gasVoltage ?? this.gasVoltage,
      smokeRaw: smokeRaw ?? this.smokeRaw,
      fireAngle: fireAngle ?? this.fireAngle,
      riskScore: riskScore ?? this.riskScore,
      fireState: fireState ?? this.fireState,
      responseStatus: responseStatus ?? this.responseStatus,
      sensorsValid: sensorsValid ?? this.sensorsValid,
      wifiRssi: wifiRssi ?? this.wifiRssi,
    );
  }
}
