class ReportModel {
  final String id;
  final String period; // 'Daily', 'Weekly', 'Monthly', 'Yearly'
  final DateTime startDate;
  final DateTime endDate;
  final double averageTemperature;
  final double maxCoLevel;
  final int totalAlerts;
  final double averageUptimePercentage;
  final List<double> historicalDataPoints; // e.g., temperature over time for the chart

  const ReportModel({
    required this.id,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.averageTemperature,
    required this.maxCoLevel,
    required this.totalAlerts,
    required this.averageUptimePercentage,
    required this.historicalDataPoints,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      period: json['period'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      averageTemperature: (json['averageTemperature'] as num).toDouble(),
      maxCoLevel: (json['maxCoLevel'] as num).toDouble(),
      totalAlerts: json['totalAlerts'] as int,
      averageUptimePercentage: (json['averageUptimePercentage'] as num).toDouble(),
      historicalDataPoints: (json['historicalDataPoints'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'averageTemperature': averageTemperature,
      'maxCoLevel': maxCoLevel,
      'totalAlerts': totalAlerts,
      'averageUptimePercentage': averageUptimePercentage,
      'historicalDataPoints': historicalDataPoints,
    };
  }
}
