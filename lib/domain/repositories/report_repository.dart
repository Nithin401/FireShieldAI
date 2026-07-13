import 'package:fireshield_app/domain/models/report_model.dart';

abstract class ReportRepository {
  /// Fetches a report summary for a specific period
  Future<ReportModel> getReportForPeriod(String period);

  /// Requests the backend to generate and email a PDF export
  Future<void> exportReportAsPdf(String period);

  /// Requests the backend to generate and email a CSV export
  Future<void> exportReportAsCsv(String period);
}
