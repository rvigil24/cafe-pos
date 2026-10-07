import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../application/services/cafe_calendar.dart';
import '../application/services/id_generator.dart';
import '../application/use_cases/catalog_use_cases.dart';
import '../application/use_cases/order_use_cases.dart';
import '../application/use_cases/payment_use_cases.dart';
import '../application/use_cases/report_use_cases.dart';
import '../application/use_cases/sales_use_cases.dart';
import '../application/use_cases/table_use_cases.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/database/sqlite_transaction_runner.dart';
import '../infrastructure/repositories/sqlite_category_repository.dart';
import '../infrastructure/repositories/sqlite_order_repository.dart';
import '../infrastructure/repositories/sqlite_product_repository.dart';
import '../infrastructure/repositories/sqlite_report_repository.dart';
import '../infrastructure/repositories/sqlite_sales_repository.dart';
import '../infrastructure/repositories/sqlite_table_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.catalog,
    required this.tables,
    required this.orders,
    required this.payments,
    required this.sales,
    required this.reports,
  });

  final CatalogUseCases catalog;
  final TableUseCases tables;
  final OrderUseCases orders;
  final PaymentUseCases payments;
  final SalesUseCases sales;
  final ReportUseCases reports;
}

Future<AppDependencies> buildAppDependencies() async {
  tz_data.initializeTimeZones();
  final AppDatabase database = AppDatabase();
  await database.initialize();
  final SqliteCategoryRepository categories = SqliteCategoryRepository(
    database,
  );
  final SqliteProductRepository products = SqliteProductRepository(database);
  final SqliteTableRepository tables = SqliteTableRepository(database);
  final SqliteOrderRepository orders = SqliteOrderRepository(database);
  final location = tz.getLocation('America/El_Salvador');
  final CafeCalendar calendar = CafeCalendar(location);
  const UuidIdGenerator ids = UuidIdGenerator();
  return AppDependencies(
    catalog: CatalogUseCases(
      categories: categories,
      products: products,
      ids: ids,
      clock: DateTime.now,
    ),
    tables: TableUseCases(tables: tables, ids: ids, clock: DateTime.now),
    orders: OrderUseCases(
      tables: tables,
      orders: orders,
      categories: categories,
      products: products,
      transactions: SqliteTransactionRunner(database),
      ids: ids,
      clock: DateTime.now,
    ),
    payments: PaymentUseCases(
      orders: orders,
      transactions: SqliteTransactionRunner(database),
      ids: ids,
      clock: DateTime.now,
    ),
    sales: SalesUseCases(
      sales: SqliteSalesRepository(database),
      calendar: calendar,
    ),
    reports: ReportUseCases(
      reports: SqliteReportRepository(database, location),
      calendar: calendar,
      clock: DateTime.now,
    ),
  );
}
