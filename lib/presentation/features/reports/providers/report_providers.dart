import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fireshield_app/domain/models/report_model.dart';
import 'package:fireshield_app/presentation/providers/repository_providers.dart';

// NotifierProvider to hold the currently selected period tab
class ReportPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'Daily';
  void setPeriod(String period) => state = period;
}
final reportPeriodProvider = NotifierProvider<ReportPeriodNotifier, String>(ReportPeriodNotifier.new);

// FutureProvider to fetch the report data based on the selected period
final currentReportProvider = FutureProvider<ReportModel>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getReportForPeriod(period);
});
