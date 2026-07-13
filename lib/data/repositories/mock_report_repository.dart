import 'dart:math';
import 'package:fireshield_app/domain/models/report_model.dart';
import 'package:fireshield_app/domain/repositories/report_repository.dart';

class MockReportRepository implements ReportRepository {
  final _random = Random();

  @override
  Future<ReportModel> getReportForPeriod(String period) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate mock data based on the requested period
    int dataPointsCount = period == 'Daily' ? 24 : period == 'Weekly' ? 7 : period == 'Monthly' ? 30 : 12;
    
    List<double> dataPoints = List.generate(
      dataPointsCount, 
      (index) => 20.0 + _random.nextDouble() * 10,
    );

    return ReportModel(
      id: 'rep_${period.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      period: period,
      startDate: DateTime.now().subtract(Duration(days: period == 'Weekly' ? 7 : period == 'Monthly' ? 30 : 1)),
      endDate: DateTime.now(),
      averageTemperature: 24.5 + _random.nextDouble() * 2,
      maxCoLevel: 1.2 + _random.nextDouble(),
      totalAlerts: _random.nextInt(5),
      averageUptimePercentage: 98.0 + _random.nextDouble() * 1.9,
      historicalDataPoints: dataPoints,
    );
  }

  @override
  Future<void> exportReportAsPdf(String period) async {
    await Future.delayed(const Duration(seconds: 2));
    // In a real app, this would trigger a cloud function to generate and download a PDF
  }

  @override
  Future<void> exportReportAsCsv(String period) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
