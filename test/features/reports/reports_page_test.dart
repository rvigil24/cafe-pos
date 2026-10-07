import 'package:cafe_pos/application/services/cafe_calendar.dart';
import 'package:cafe_pos/application/use_cases/report_use_cases.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/domain/entities/sales_report.dart';
import 'package:cafe_pos/features/reports/controllers/reports_controller.dart';
import 'package:cafe_pos/features/reports/pages/reports_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../support/fakes.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  testWidgets('shows readable values for every report group', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final FakeReportRepository repository = FakeReportRepository()
      ..value = const SalesReport(
        netSalesCents: 1500,
        paidOrderCount: 2,
        unitsSold: 6,
        bestSellingProducts: <ProductUnits>[
          ProductUnits(name: 'Café', units: 5),
        ],
        salesByCategory: <NamedSalesTotal>[
          NamedSalesTotal(name: 'Bebidas', totalCents: 1300),
        ],
        salesByHour: <HourlySalesTotal>[
          HourlySalesTotal(hour: 14, totalCents: 500),
        ],
        totalsByPaymentMethod: <PaymentMethodTotal>[
          PaymentMethodTotal(method: PaymentMethod.cash, totalCents: 1000),
        ],
      );
    final ReportsController controller = ReportsController(
      ReportUseCases(
        reports: repository,
        calendar: CafeCalendar(tz.getLocation('America/El_Salvador')),
        clock: () => DateTime.utc(2026, 10, 6, 18),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ReportsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ventas netas'), findsOneWidget);
    expect(find.text('15.00'), findsOneWidget);
    expect(find.text('Ticket promedio'), findsOneWidget);
    expect(find.text('7.50'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('5 unidades'), findsOneWidget);
    expect(find.text('Bebidas'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
  });

  testWidgets('shows the report empty state', (WidgetTester tester) async {
    final FakeReportRepository repository = FakeReportRepository();
    final ReportsController controller = ReportsController(
      ReportUseCases(
        reports: repository,
        calendar: CafeCalendar(tz.getLocation('America/El_Salvador')),
        clock: () => DateTime.utc(2026, 10, 6, 18),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ReportsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay ventas pagadas en este período.'), findsOneWidget);
  });
}
