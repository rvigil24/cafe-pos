import 'package:flutter/foundation.dart';

import '../../../application/services/cafe_calendar.dart';
import '../../../application/use_cases/report_use_cases.dart';
import '../../../domain/entities/sales_report.dart';
import '../../../domain/errors/domain_error.dart';

enum ReportsStatus { loading, ready, error }

class ReportsController extends ChangeNotifier {
  ReportsController(this._reports);

  final ReportUseCases _reports;

  ReportsStatus status = ReportsStatus.loading;
  ReportPeriod period = ReportPeriod.today;
  DateTime? customStart;
  DateTime? customEnd;
  SalesReport? report;
  String? errorMessage;

  Future<void> load({
    ReportPeriod? period,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    if (period != null) {
      this.period = period;
    }
    if (this.period == ReportPeriod.custom) {
      this.customStart = customStart ?? this.customStart;
      this.customEnd = customEnd ?? this.customEnd;
    }
    status = ReportsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final ReportResult result = await _reports.load(
        this.period,
        customStart: this.customStart,
        customEnd: this.customEnd,
      );
      report = result.report;
      status = ReportsStatus.ready;
    } on Object catch (error) {
      status = ReportsStatus.error;
      errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  String _messageFor(Object error) {
    if (error is DomainError) {
      return error.message;
    }
    return 'No se pudo cargar el reporte. Intenta nuevamente.';
  }
}
