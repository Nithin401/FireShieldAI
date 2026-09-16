class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String severity; // 'info', 'warning', 'critical'
  final String? deviceId;
  final String? roomId;
  final String? fireState;
  final double? riskScore;
  final int? fireAngle;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.severity,
    this.deviceId,
    this.roomId,
    this.fireState,
    this.riskScore,
    this.fireAngle,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      parsedTime = json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now();
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return NotificationModel(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? 'Alert Notification') as String,
      message: (json['message'] ?? '') as String,
      timestamp: parsedTime,
      isRead: (json['isRead'] ?? json['acknowledged']) as bool? ?? false,
      severity: (json['severity'] ?? 'info') as String,
      deviceId: json['deviceId'] as String?,
      roomId: json['roomId'] as String?,
      fireState: json['fireState'] as String?,
      riskScore: json['riskScore'] != null ? (json['riskScore'] as num).toDouble() : null,
      fireAngle: json['fireAngle'] != null ? (json['fireAngle'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'severity': severity,
      if (deviceId != null) 'deviceId': deviceId,
      if (roomId != null) 'roomId': roomId,
      if (fireState != null) 'fireState': fireState,
      if (riskScore != null) 'riskScore': riskScore,
      if (fireAngle != null) 'fireAngle': fireAngle,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? severity,
    String? deviceId,
    String? roomId,
    String? fireState,
    double? riskScore,
    int? fireAngle,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      severity: severity ?? this.severity,
      deviceId: deviceId ?? this.deviceId,
      roomId: roomId ?? this.roomId,
      fireState: fireState ?? this.fireState,
      riskScore: riskScore ?? this.riskScore,
      fireAngle: fireAngle ?? this.fireAngle,
    );
  }
}

