import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/application/use_cases/payment_use_cases.dart';
import 'package:cafe_pos/domain/entities/order.dart';
import 'package:cafe_pos/domain/entities/order_item.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 5, 18);
  late FakeOrderRepository orders;
  late FakePaymentRepository payments;
  late PaymentUseCases useCases;

  setUp(() {
    orders = FakeOrderRepository();
    payments = FakePaymentRepository();
    final TransactionRepositories repositories = TransactionRepositories(
      categories: FakeCategoryRepository(),
      products: FakeProductRepository(),
      tables: FakeTableRepository(),
      orders: orders,
      payments: payments,
      settings: FakeSettingsRepository(),
    );
    useCases = PaymentUseCases(
      orders: orders,
      transactions: DirectTransactionRunner(repositories),
      ids: FixedIds(),
      clock: () => now,
    );
    orders.orders.add(_order(now));
    orders.items.add(_item(now, unitPriceCents: 250));
  });

  test('records cash for the current total and calculates change', () async {
    final PaymentResult result = await useCases.pay(
      orderId: 'order-1',
      method: PaymentMethod.cash,
      receivedCents: 500,
    );

    expect(result.payment.amountCents, 250);
    expect(result.payment.receivedCents, 500);
    expect(result.changeCents, 250);
    expect(result.payment.createdAt.isUtc, isTrue);
    expect(payments.values, hasLength(1));
    expect(orders.orders.single.status, OrderStatus.paid);
    expect(orders.orders.single.paidAt, now);
  });

  test('rejects missing items but permits a zero-priced item', () async {
    orders.items.clear();
    await expectLater(
      useCases.pay(
        orderId: 'order-1',
        method: PaymentMethod.cash,
        receivedCents: 0,
      ),
      throwsA(isA<PaymentNotAllowedError>()),
    );

    orders.items.add(_item(now, unitPriceCents: 0));
    final PaymentResult result = await useCases.pay(
      orderId: 'order-1',
      method: PaymentMethod.cash,
      receivedCents: 0,
    );
    expect(result.payment.amountCents, 0);
  });

  test('rejects cash below the recalculated total', () async {
    await expectLater(
      useCases.pay(
        orderId: 'order-1',
        method: PaymentMethod.cash,
        receivedCents: 249,
      ),
      throwsA(
        isA<ValidationError>().having(
          (ValidationError error) => error.field,
          'field',
          'received',
        ),
      ),
    );
    expect(payments.values, isEmpty);
    expect(orders.orders.single.status, OrderStatus.open);
  });

  test(
    'requires manual confirmation for transfer and trims reference',
    () async {
      await expectLater(
        useCases.pay(
          orderId: 'order-1',
          method: PaymentMethod.transfer,
          reference: ' comprobante-1 ',
        ),
        throwsA(isA<ValidationError>()),
      );

      final PaymentResult result = await useCases.pay(
        orderId: 'order-1',
        method: PaymentMethod.transfer,
        reference: ' comprobante-1 ',
        manualConfirmed: true,
      );
      expect(result.payment.reference, 'comprobante-1');
      expect(result.payment.receivedCents, isNull);
    },
  );

  test(
    'records a manually confirmed credit card without additional data',
    () async {
      final PaymentResult result = await useCases.pay(
        orderId: 'order-1',
        method: PaymentMethod.creditCard,
        reference: 'must-be-ignored',
        manualConfirmed: true,
      );

      expect(result.payment.method, PaymentMethod.creditCard);
      expect(result.payment.reference, isNull);
      expect(result.payment.receivedCents, isNull);
    },
  );

  test('rejects a repeated payment and a cancelled order', () async {
    await useCases.pay(
      orderId: 'order-1',
      method: PaymentMethod.cash,
      receivedCents: 250,
    );
    await expectLater(
      useCases.pay(
        orderId: 'order-1',
        method: PaymentMethod.cash,
        receivedCents: 250,
      ),
      throwsA(isA<DuplicatePaymentError>()),
    );

    orders.orders.add(
      _order(now, id: 'cancelled', status: OrderStatus.cancelled),
    );
    orders.items.add(_item(now, orderId: 'cancelled'));
    await expectLater(
      useCases.pay(
        orderId: 'cancelled',
        method: PaymentMethod.cash,
        receivedCents: 250,
      ),
      throwsA(isA<PaymentNotAllowedError>()),
    );
  });
}

Order _order(
  DateTime now, {
  String id = 'order-1',
  OrderStatus status = OrderStatus.open,
}) {
  return Order(
    id: id,
    orderNumber: id == 'order-1' ? 1 : 2,
    tableId: null,
    tableNameSnapshot: null,
    type: OrderType.takeaway,
    status: status,
    totalCents: 250,
    createdAt: now,
    updatedAt: now,
    paidAt: null,
    cancelledAt: status == OrderStatus.cancelled ? now : null,
    cancellationReason: status == OrderStatus.cancelled ? 'Prueba' : null,
  );
}

OrderItem _item(
  DateTime now, {
  String orderId = 'order-1',
  int unitPriceCents = 250,
}) {
  return OrderItem(
    id: 'item-$orderId',
    orderId: orderId,
    productId: 'product-1',
    productNameSnapshot: 'Café',
    categoryNameSnapshot: 'Bebidas',
    quantity: 1,
    unitPriceCents: unitPriceCents,
    note: null,
    createdAt: now,
    updatedAt: now,
  );
}
