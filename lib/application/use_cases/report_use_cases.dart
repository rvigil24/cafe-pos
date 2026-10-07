import '../../domain/entities/sales_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../services/cafe_calendar.dart';

typedef ReportClock = DateTime Function();

class ReportResult {
  const ReportResult({required this.period, required this.report});

  final ReportPeriod period;
  final SalesReport report;
}

class ReportUseCases {
  const ReportUseCases({
    required ReportRepository reports,
    required CafeCalendar calendar,
    required ReportClock clock,
  }) : this._(reports, calendar, clock);

  const ReportUseCases._(this._reports, this._calendar, this._clock);

  final ReportRepository _reports;
  final CafeCalendar _calendar;
  final ReportClock _clock;

  Future<ReportResult> load(
    ReportPeriod period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final range = _calendar.reportRange(
      period,
      _clock(),
      customStart: customStart,
      customEnd: customEnd,
    );
    return ReportResult(period: period, report: await _reports.load(range));
  }
}
