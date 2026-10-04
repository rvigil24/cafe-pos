import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/application/use_cases/order_use_cases.dart';
import 'package:cafe_pos/domain/entities/cafe_table.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/order.dart';
import 'package:cafe_pos/domain/entities/order_details.dart';
import 'package:cafe_pos/domain/entities/product.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 3, 16);
  late FakeCategoryRepository categories;
  late FakeProductRepository products;
  late FakeTableRepository tables;
  late FakeOrderRepository orders;
  late FakeSettingsRepository settings;
  late OrderUseCases useCases;
  late CafeTable table;
  late Category category;
  late Product product;

  setUp(() {
    categories = FakeCategoryRepository();
    products = FakeProductRepository();
    tables = FakeTableRepository();
    orders = FakeOrderRepository();
    settings = FakeSettingsRepository();
    table = CafeTable(
      id: 'table-1',
      name: 'Mesa 1',
      sortOrder: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    category = Category(
      id: 'category-1',
      name: 'Bebidas',
      sortOrder: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    product = Product(
      id: 'product-1',
      categoryId: category.id,
      name: 'Café',
      priceCents: 250,
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    tables.values.add(table);
    categories.values.add(category);
    products.values.add(product);
    final TransactionRepositories repositories = TransactionRepositories(
      categories: categories,
      products: products,
      tables: tables,
      orders: orders,
      settings: settings,
    );
    useCases = OrderUseCases(
      tables: tables,
      orders: orders,
      categories: categories,
      products: products,
      transactions: DirectTransactionRunner(repositories),
      ids: FixedIds(),
      clock: () => now,
    );
  });

  test(
    'creates sequential dine-in and takeaway orders with snapshots',
    () async {
      final Order dineIn = await useCases.createDineIn(table.id);
      final Order takeaway = await useCases.createTakeaway();

      expect(dineIn.orderNumber, 1);
      expect(dineIn.tableId, table.id);
      expect(dineIn.tableNameSnapshot, 'Mesa 1');
      expect(dineIn.type, OrderType.dineIn);
      expect(takeaway.orderNumber, 2);
      expect(takeaway.tableId, isNull);
      expect(takeaway.type, OrderType.takeaway);
    },
  );

  test('rejects an inactive or occupied table', () async {
    await useCases.createDineIn(table.id);

    await expectLater(
      useCases.createDineIn(table.id),
      throwsA(isA<TableUnavailableError>()),
    );
    tables.values[0] = table.copyWith(isActive: false);
    await expectLater(
      useCases.createDineIn(table.id),
      throwsA(isA<TableUnavailableError>()),
    );
  });

  test(
    'adds one snapshotted line and increments it at its old price',
    () async {
      final Order order = await useCases.createDineIn(table.id);
      OrderDetails details = await useCases.addProduct(order.id, product.id);
      products.values[0] = product.copyWith(priceCents: 300);
      details = await useCases.addProduct(order.id, product.id);

      expect(details.items, hasLength(1));
      expect(details.items.single.quantity, 2);
      expect(details.items.single.unitPriceCents, 250);
      expect(details.items.single.productNameSnapshot, 'Café');
      expect(details.items.single.categoryNameSnapshot, 'Bebidas');
      expect(details.order.totalCents, 500);
    },
  );

  test(
    'changes quantity, removes a line, and saves or clears its note',
    () async {
      final Order order = await useCases.createTakeaway();
      OrderDetails details = await useCases.addProduct(order.id, product.id);
      final String itemId = details.items.single.id;

      details = await useCases.setQuantity(order.id, itemId, 3);
      expect(details.order.totalCents, 750);
      details = await useCases.saveNote(order.id, itemId, '  sin azúcar ');
      expect(details.items.single.note, 'sin azúcar');
      details = await useCases.saveNote(order.id, itemId, ' ');
      expect(details.items.single.note, isNull);
      details = await useCases.setQuantity(order.id, itemId, 0);
      expect(details.items, isEmpty);
      expect(details.order.totalCents, 0);
    },
  );

  test(
    'unavailable persisted products can decrease but not increase',
    () async {
      final Order order = await useCases.createTakeaway();
      OrderDetails details = await useCases.addProduct(order.id, product.id);
      details = await useCases.setQuantity(
        order.id,
        details.items.single.id,
        2,
      );
      products.values[0] = product.copyWith(isAvailable: false);

      await expectLater(
        useCases.setQuantity(order.id, details.items.single.id, 3),
        throwsA(isA<ProductUnavailableError>()),
      );
      details = await useCases.setQuantity(
        order.id,
        details.items.single.id,
        1,
      );
      expect(details.items.single.quantity, 1);
    },
  );

  test('cancel requires a reason, records it, and frees the table', () async {
    final Order order = await useCases.createDineIn(table.id);

    await expectLater(
      useCases.cancelOrder(order.id, ' '),
      throwsA(isA<ValidationError>()),
    );
    await useCases.cancelOrder(order.id, ' Cliente se retiró ');
    final OrderDetails cancelled = (await orders.findDetails(order.id))!;

    expect(cancelled.order.status, OrderStatus.cancelled);
    expect(cancelled.order.cancellationReason, 'Cliente se retiró');
    expect(cancelled.order.cancelledAt, now);
    expect((await useCases.createDineIn(table.id)).orderNumber, 2);
  });

  test('rejects mutations to paid and cancelled orders', () async {
    final Order cancelled = await useCases.createTakeaway();
    await useCases.cancelOrder(cancelled.id, 'Error');

    await expectLater(
      useCases.addProduct(cancelled.id, product.id),
      throwsA(isA<OrderNotEditableError>()),
    );
    final Order paid = Order(
      id: 'paid',
      orderNumber: 8,
      tableId: null,
      tableNameSnapshot: null,
      type: OrderType.takeaway,
      status: OrderStatus.paid,
      totalCents: 250,
      createdAt: now,
      updatedAt: now,
      paidAt: now,
      cancelledAt: null,
      cancellationReason: null,
    );
    orders.orders.add(paid);
    await expectLater(
      useCases.addProduct(paid.id, product.id),
      throwsA(isA<OrderNotEditableError>()),
    );
  });
}
