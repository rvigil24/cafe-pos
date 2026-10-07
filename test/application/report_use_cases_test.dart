import 'package:cafe_pos/application/services/cafe_calendar.dart';
import 'package:cafe_pos/application/use_cases/report_use_cases.dart';
import 'package:cafe_pos/domain/entities/sales_report.dart';
import 'package:cafe_pos/domain/entities/utc_date_range.dart';
import 'package:cafe_pos/domain/repositories/report_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('loads a report with the selected cafe-calendar period', () async {
    final _RecordingReportRepository repository = _RecordingReportRepository();
    final ReportUseCases useCases = ReportUseCases(
      reports: repository,
      calendar: CafeCalendar(tz.getLocation('America/El_Salvador')),
      clock: () => DateTime.utc(2026, 10, 6, 18),
    );

    final ReportResult result = await useCases.load(ReportPeriod.today);

    expect(result.period, ReportPeriod.today);
    expect(repository.range?.start, DateTime.utc(2026, 10, 6, 6));
    expect(repository.range?.end, DateTime.utc(2026, 10, 7, 6));
  });

  test('rounds average ticket to the nearest cent with integer math', () {
    const SalesReport report = SalesReport(
      netSalesCents: 100,
      paidOrderCount: 3,
      unitsSold: 0,
      bestSellingProducts: <ProductUnits>[],
      salesByCategory: <NamedSalesTotal>[],
      salesByHour: <HourlySalesTotal>[],
      totalsByPaymentMethod: <PaymentMethodTotal>[],
    );

    expect(report.averageTicketCents, 33);
  });
}

class _RecordingReportRepository implements ReportRepository {
  UtcDateRange? range;

  @override
  Future<SalesReport> load(UtcDateRange paidRange) async {
    range = paidRange;
    return const SalesReport(
      netSalesCents: 0,
      paidOrderCount: 0,
      unitsSold: 0,
      bestSellingProducts: <ProductUnits>[],
      salesByCategory: <NamedSalesTotal>[],
      salesByHour: <HourlySalesTotal>[],
      totalsByPaymentMethod: <PaymentMethodTotal>[],
    );
  }
}
