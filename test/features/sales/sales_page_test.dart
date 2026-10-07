import 'package:cafe_pos/application/services/cafe_calendar.dart';
import 'package:cafe_pos/application/use_cases/sales_use_cases.dart';
import 'package:cafe_pos/domain/entities/order.dart';
import 'package:cafe_pos/domain/entities/order_item.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/domain/entities/sale.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/features/sales/controllers/sales_controller.dart';
import 'package:cafe_pos/features/sales/pages/sales_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../support/fakes.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  testWidgets('lists a persisted sale and opens read-only payment details', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final FakeSalesRepository repository = FakeSalesRepository();
    final SaleSummary sale = SaleSummary(
      orderId: 'order-1',
      orderNumber: 7,
      type: OrderType.dineIn,
      tableNameSnapshot: 'Mesa histórica',
      totalCents: 500,
      paidAt: DateTime.utc(2026, 10, 6, 16),
      paymentMethod: PaymentMethod.cash,
    );
    repository.values.add(sale);
    repository.details[sale.orderId] = SaleDetails(
      sale: sale,
      items: <OrderItem>[
        OrderItem(
          id: 'item-1',
          orderId: sale.orderId,
          productId: null,
          productNameSnapshot: 'Café histórico',
          categoryNameSnapshot: 'Bebidas históricas',
          quantity: 2,
          unitPriceCents: 250,
          note: 'Sin azúcar',
          createdAt: sale.paidAt,
          updatedAt: sale.paidAt,
        ),
      ],
      payment: Payment(
        id: 'payment-1',
        orderId: sale.orderId,
        method: PaymentMethod.cash,
        amountCents: 500,
        receivedCents: 1000,
        reference: null,
        createdAt: sale.paidAt,
      ),
    );
    final SalesController controller = SalesController(
      SalesUseCases(
        sales: repository,
        calendar: CafeCalendar(tz.getLocation('America/El_Salvador')),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: SalesPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Orden #7'), findsOneWidget);
    expect(find.textContaining('Mesa histórica'), findsOneWidget);
    await tester.tap(find.text('Orden #7'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Café histórico'), findsOneWidget);
    expect(find.textContaining('Sin azúcar'), findsOneWidget);
    expect(find.text('Recibido'), findsOneWidget);
    expect(find.text('10.00'), findsOneWidget);
    expect(find.text('Cambio'), findsOneWidget);
    expect(find.text('5.00'), findsAtLeastNWidgets(2));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un número de orden válido.'), findsOneWidget);
  });

  testWidgets('shows empty and recoverable error states', (
    WidgetTester tester,
  ) async {
    final FakeSalesRepository repository = FakeSalesRepository();
    final SalesController controller = SalesController(
      SalesUseCases(
        sales: repository,
        calendar: CafeCalendar(tz.getLocation('America/El_Salvador')),
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: SalesPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No hay ventas que coincidan con los filtros.'),
      findsOneWidget,
    );

    repository.error = const PersistenceError('Error recuperable');
    await controller.load();
    await tester.pumpAndSettle();
    expect(find.text('Error recuperable'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsWidgets);
  });
}
