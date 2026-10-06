import 'dart:async';

import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/application/use_cases/payment_use_cases.dart';
import 'package:cafe_pos/domain/entities/order.dart';
import 'package:cafe_pos/domain/entities/order_item.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/features/payments/controllers/payment_controller.dart';
import 'package:cafe_pos/features/payments/pages/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('cash payment displays change and submits once', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _Fixture();
    PaymentResult? paid;
    await _pumpLandscape(
      tester,
      PaymentPage(
        controller: PaymentController(fixture.useCases, fixture.order.id),
        onBack: () {},
        onPaid: (PaymentResult result) => paid = result,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Monto recibido'),
      '5.00',
    );
    await tester.pump();
    expect(find.text('Cambio: 2.50'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pago'));
    await tester.pumpAndSettle();
    expect(paid, isNotNull);
    expect(paid!.payment.method, PaymentMethod.cash);
    expect(fixture.payments.values, hasLength(1));
    expect(fixture.orders.orders.single.status, OrderStatus.paid);
  });

  testWidgets('credit card requires confirmation and warns against card data', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _Fixture();
    PaymentResult? paid;
    await _pumpLandscape(
      tester,
      PaymentPage(
        controller: PaymentController(fixture.useCases, fixture.order.id),
        onBack: () {},
        onPaid: (PaymentResult result) => paid = result,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tarjeta de crédito'));
    await tester.pump();
    expect(
      find.text(
        'No ingreses número de tarjeta, vencimiento ni código de seguridad.',
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, 'Referencia o comprobante (opcional)'),
      findsNothing,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pago'));
    await tester.pump();
    expect(
      find.text('Confirma que el pago fue verificado manualmente.'),
      findsOneWidget,
    );
    expect(paid, isNull);

    await tester.tap(
      find.text('Confirmo que el cobro con tarjeta fue verificado.'),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pago'));
    await tester.pumpAndSettle();
    expect(paid!.payment.method, PaymentMethod.creditCard);
    expect(paid!.payment.reference, isNull);
  });

  test(
    'controller ignores a repeated submit while payment is running',
    () async {
      final _Fixture fixture = _Fixture(blockTransactions: true);
      final PaymentController controller = PaymentController(
        fixture.useCases,
        fixture.order.id,
      );
      await controller.load();

      final Future<PaymentResult?> first = controller.submit(
        rawReceived: '2.50',
        reference: '',
      );
      expect(controller.isSubmitting, isTrue);
      expect(
        await controller.submit(rawReceived: '2.50', reference: ''),
        isNull,
      );
      (fixture.runner as _BlockingTransactionRunner).release();
      expect(await first, isNotNull);
      expect(fixture.payments.values, hasLength(1));
    },
  );
}

Future<void> _pumpLandscape(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: child));
}

class _Fixture {
  _Fixture({bool blockTransactions = false}) {
    orders.orders.add(order);
    orders.items.add(
      OrderItem(
        id: 'item-1',
        orderId: order.id,
        productId: 'product-1',
        productNameSnapshot: 'Café',
        categoryNameSnapshot: 'Bebidas',
        quantity: 1,
        unitPriceCents: 250,
        note: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final TransactionRepositories repositories = TransactionRepositories(
      categories: FakeCategoryRepository(),
      products: FakeProductRepository(),
      tables: FakeTableRepository(),
      orders: orders,
      payments: payments,
      settings: FakeSettingsRepository(),
    );
    runner = blockTransactions
        ? _BlockingTransactionRunner(repositories)
        : DirectTransactionRunner(repositories);
    useCases = PaymentUseCases(
      orders: orders,
      transactions: runner,
      ids: FixedIds(),
      clock: () => now,
    );
  }

  final DateTime now = DateTime.utc(2026, 10, 5, 18);
  final FakeOrderRepository orders = FakeOrderRepository();
  final FakePaymentRepository payments = FakePaymentRepository();
  late final TransactionRunner runner;
  late final PaymentUseCases useCases;
  late final Order order = Order(
    id: 'order-1',
    orderNumber: 1,
    tableId: null,
    tableNameSnapshot: null,
    type: OrderType.takeaway,
    status: OrderStatus.open,
    totalCents: 250,
    createdAt: now,
    updatedAt: now,
    paidAt: null,
    cancelledAt: null,
    cancellationReason: null,
  );
}

class _BlockingTransactionRunner implements TransactionRunner {
  _BlockingTransactionRunner(this.repositories);

  final TransactionRepositories repositories;
  final Completer<void> _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<T> run<T>(
    Future<T> Function(TransactionRepositories repositories) operation,
  ) async {
    await _gate.future;
    return operation(repositories);
  }
}
