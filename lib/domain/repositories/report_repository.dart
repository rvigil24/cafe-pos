import '../entities/sales_report.dart';
import '../entities/utc_date_range.dart';

abstract interface class ReportRepository {
  Future<SalesReport> load(UtcDateRange paidRange);
}
