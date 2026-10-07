import 'package:cafe_pos/app/app.dart';
import 'package:cafe_pos/app/dependencies.dart';
import 'package:cafe_pos/application/services/cafe_calendar.dart';
import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/application/use_cases/catalog_use_cases.dart';
import 'package:cafe_pos/application/use_cases/order_use_cases.dart';
import 'package:cafe_pos/application/use_cases/payment_use_cases.dart';
import 'package:cafe_pos/application/use_cases/report_use_cases.dart';
import 'package:cafe_pos/application/use_cases/sales_use_cases.dart';
import 'package:cafe_pos/application/use_cases/table_use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../support/fakes.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  testWidgets('opens Sales and Reports from the tablet navigation rail', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final AppDependencies dependencies = _dependencies();

    await tester.pumpWidget(CafePosApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ventas'), findsOneWidget);
    expect(
      find.text('No hay ventas que coincidan con los filtros.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Reportes'), findsOneWidget);
    expect(find.text('No hay ventas pagadas en este período.'), findsOneWidget);
  });
}

AppDependencies _dependencies() {
  final FakeCategoryRepository categories = FakeCategoryRepository();
  final FakeProductRepository products = FakeProductRepository();
  final FakeTableRepository tables = FakeTableRepository();
  final FakeOrderRepository orders = FakeOrderRepository();
  final FakePaymentRepository payments = FakePaymentRepository();
  final FakeSettingsRepository settings = FakeSettingsRepository();
  final DirectTransactionRunner transactions = DirectTransactionRunner(
    TransactionRepositories(
      categories: categories,
      products: products,
      tables: tables,
      orders: orders,
      payments: payments,
      settings: settings,
    ),
  );
  final FixedIds ids = FixedIds();
  final DateTime now = DateTime.utc(2026, 10, 6, 18);
  final CafeCalendar calendar = CafeCalendar(
    tz.getLocation('America/El_Salvador'),
  );
  return AppDependencies(
    catalog: CatalogUseCases(
      categories: categories,
      products: products,
      ids: ids,
      clock: () => now,
    ),
    tables: TableUseCases(tables: tables, ids: ids, clock: () => now),
    orders: OrderUseCases(
      tables: tables,
      orders: orders,
      categories: categories,
      products: products,
      transactions: transactions,
      ids: ids,
      clock: () => now,
    ),
    payments: PaymentUseCases(
      orders: orders,
      transactions: transactions,
      ids: ids,
      clock: () => now,
    ),
    sales: SalesUseCases(sales: FakeSalesRepository(), calendar: calendar),
    reports: ReportUseCases(
      reports: FakeReportRepository(),
      calendar: calendar,
      clock: () => now,
    ),
  );
}
