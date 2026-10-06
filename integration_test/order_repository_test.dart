import 'dart:io';

import 'package:cafe_pos/application/services/id_generator.dart';
import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/application/use_cases/catalog_use_cases.dart';
import 'package:cafe_pos/application/use_cases/order_use_cases.dart';
import 'package:cafe_pos/application/use_cases/payment_use_cases.dart';
import 'package:cafe_pos/application/use_cases/table_use_cases.dart';
import 'package:cafe_pos/domain/entities/cafe_table.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/order.dart';
import 'package:cafe_pos/domain/entities/order_details.dart';
import 'package:cafe_pos/domain/entities/order_item.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/domain/entities/product.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/infrastructure/database/app_database.dart';
import 'package:cafe_pos/infrastructure/database/sqlite_transaction_runner.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_category_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_order_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_payment_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_product_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_settings_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_table_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String databasePath;
  final DateTime now = DateTime.utc(2026, 10, 3, 18);

  setUp(() async {
    final Directory directory = await getTemporaryDirectory();
    databasePath = path.join(directory.path, 'order_repository_test.db');
    await deleteDatabase(databasePath);
  });

  tearDown(() => deleteDatabase(databasePath));

  testWidgets('persists, reopens, and cancels dine-in and takeaway orders', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = await _Fixture.create(databasePath, now);

    final Order dineIn = await fixture.orders.createDineIn(fixture.table.id);
    OrderDetails details = await fixture.orders.addProduct(
      dineIn.id,
      fixture.product.id,
    );
    details = await fixture.orders.addProduct(dineIn.id, fixture.product.id);
    details = await fixture.orders.saveNote(
      dineIn.id,
      details.items.single.id,
      'Sin azúcar',
    );

    expect(details.items, hasLength(1));
    expect(details.items.single.quantity, 2);
    expect(details.items.single.unitPriceCents, 250);
    expect(details.order.totalCents, 500);

    await fixture.catalog.editProduct(
      product: fixture.product,
      categoryId: fixture.category.id,
      name: 'Espresso',
      price: '3.00',
    );
    await fixture.tables.renameTable(fixture.table, 'Terraza');

    await fixture.provider.close();
    final _Fixture reopened = await _Fixture.openExisting(databasePath, now);
    final OrderDetails persisted = await reopened.orders.loadOrder(dineIn.id);
    expect(persisted.order.tableNameSnapshot, 'Mesa 1');
    expect(persisted.items.single.productNameSnapshot, 'Café');
    expect(persisted.items.single.categoryNameSnapshot, 'Bebidas');
    expect(persisted.items.single.unitPriceCents, 250);
    expect(persisted.items.single.note, 'Sin azúcar');

    await reopened.catalog.setProductAvailable(reopened.product, false);
    await expectLater(
      reopened.orders.setQuantity(dineIn.id, persisted.items.single.id, 3),
      throwsA(isA<ProductUnavailableError>()),
    );
    final OrderDetails decreased = await reopened.orders.setQuantity(
      dineIn.id,
      persisted.items.single.id,
      1,
    );
    expect(decreased.order.totalCents, 250);

    await reopened.orders.cancelOrder(dineIn.id, 'Cliente se retiró');
    final Order takeaway = await reopened.orders.createTakeaway();
    expect(takeaway.orderNumber, 2);
    expect(
      (await reopened.orders.createDineIn(fixture.table.id)).orderNumber,
      3,
    );

    await expectLater(
      reopened.orders.addProduct(dineIn.id, fixture.product.id),
      throwsA(isA<OrderNotEditableError>()),
    );
    final Database database = await reopened.provider.database;
    final Map<String, Object?> cancelledRow = (await database.query(
      'orders',
      where: 'id = ?',
      whereArgs: <Object?>[dineIn.id],
    )).single;
    expect(cancelledRow['cancelled_at'], matches(RegExp(r'Z$')));
    expect(cancelledRow['updated_at'], matches(RegExp(r'Z$')));
    await reopened.provider.close();
  });

  testWidgets('rolls back order number and item writes after failures', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = await _Fixture.create(
      databasePath,
      now,
      ids: const _ConstantIdGenerator('same-id'),
    );
    final Order first = await fixture.orders.createTakeaway();
    expect(first.orderNumber, 1);

    await expectLater(
      fixture.orders.createTakeaway(),
      throwsA(isA<PersistenceError>()),
    );
    expect((await fixture.settings.load()).lastOrderNumber, 1);

    final OrderItem item = OrderItem(
      id: 'item-rollback',
      orderId: first.id,
      productId: fixture.product.id,
      productNameSnapshot: fixture.product.name,
      categoryNameSnapshot: fixture.category.name,
      quantity: 1,
      unitPriceCents: fixture.product.priceCents,
      note: null,
      createdAt: now,
      updatedAt: now,
    );
    await expectLater(
      fixture.transactions.run<void>((TransactionRepositories tx) async {
        await tx.orders.insertItem(item);
        throw StateError('injected failure');
      }),
      throwsStateError,
    );
    expect(
      (await fixture.orderRepository.findDetails(first.id))!.items,
      isEmpty,
    );
    await fixture.provider.close();
  });

  testWidgets('enforces occupied tables and immutable terminal orders', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = await _Fixture.create(databasePath, now);
    final Order open = await fixture.orders.createDineIn(fixture.table.id);

    await expectLater(
      fixture.tableRepository.update(
        fixture.table.copyWith(isActive: false, updatedAt: now),
      ),
      throwsA(isA<OccupiedTableError>()),
    );
    await fixture.orders.cancelOrder(open.id, 'Error de captura');
    await fixture.tableRepository.update(
      fixture.table.copyWith(isActive: false, updatedAt: now),
    );
    expect(
      (await fixture.tableRepository.findById(fixture.table.id))!.isActive,
      isFalse,
    );

    await expectLater(
      fixture.orderRepository.updateTotal(open.id, 100, now),
      throwsA(isA<OrderNotEditableError>()),
    );

    final Database database = await fixture.provider.database;
    await database.insert('orders', <String, Object?>{
      'id': 'paid-order',
      'order_number': 99,
      'table_id': null,
      'table_name_snapshot': null,
      'type': 'TAKEAWAY',
      'status': 'PAID',
      'total_cents': 250,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'paid_at': now.toIso8601String(),
    });
    await database.insert('payments', <String, Object?>{
      'id': 'paid-payment',
      'order_id': 'paid-order',
      'method': 'TRANSFER',
      'amount_cents': 250,
      'received_cents': null,
      'reference': 'fixture',
      'created_at': now.toIso8601String(),
    });
    await expectLater(
      fixture.orderRepository.updateTotal('paid-order', 300, now),
      throwsA(isA<OrderNotEditableError>()),
    );
    await expectLater(
      fixture.orderRepository.insertItem(
        OrderItem(
          id: 'paid-item',
          orderId: 'paid-order',
          productId: fixture.product.id,
          productNameSnapshot: fixture.product.name,
          categoryNameSnapshot: fixture.category.name,
          quantity: 1,
          unitPriceCents: fixture.product.priceCents,
          note: null,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<OrderNotEditableError>()),
    );
    await fixture.provider.close();
  });

  testWidgets('pays atomically, prevents duplicates, and records card', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = await _Fixture.create(databasePath, now);
    final Order dineIn = await fixture.orders.createDineIn(fixture.table.id);
    await fixture.orders.addProduct(dineIn.id, fixture.product.id);

    final PaymentResult cash = await fixture.payments.pay(
      orderId: dineIn.id,
      method: PaymentMethod.cash,
      receivedCents: 500,
    );
    expect(cash.payment.amountCents, 250);
    expect(cash.changeCents, 250);
    expect(
      (await fixture.orders.loadOrder(dineIn.id)).order.status,
      OrderStatus.paid,
    );
    expect(
      (await fixture.orders.loadHome()).orderForTable(fixture.table.id),
      isNull,
    );
    expect(
      (await fixture.paymentRepository.findByOrderId(dineIn.id))!.method,
      PaymentMethod.cash,
    );
    await expectLater(
      fixture.payments.pay(
        orderId: dineIn.id,
        method: PaymentMethod.cash,
        receivedCents: 500,
      ),
      throwsA(isA<DuplicatePaymentError>()),
    );

    final Order rollbackOrder = await fixture.orders.createTakeaway();
    await fixture.orders.addProduct(rollbackOrder.id, fixture.product.id);
    final Database database = await fixture.provider.database;
    await database.execute(
      'CREATE TRIGGER fail_paid BEFORE UPDATE OF status ON orders '
      "WHEN NEW.id = '${rollbackOrder.id}' AND NEW.status = 'PAID' "
      "BEGIN SELECT RAISE(ABORT, 'injected payment failure'); END",
    );
    await expectLater(
      fixture.payments.pay(
        orderId: rollbackOrder.id,
        method: PaymentMethod.transfer,
        manualConfirmed: true,
      ),
      throwsA(isA<PersistenceError>()),
    );
    expect(
      await fixture.paymentRepository.findByOrderId(rollbackOrder.id),
      isNull,
    );
    expect(
      (await fixture.orders.loadOrder(rollbackOrder.id)).order.status,
      OrderStatus.open,
    );
    await database.execute('DROP TRIGGER fail_paid');

    final PaymentResult card = await fixture.payments.pay(
      orderId: rollbackOrder.id,
      method: PaymentMethod.creditCard,
      reference: 'must-be-ignored',
      manualConfirmed: true,
    );
    expect(card.payment.method, PaymentMethod.creditCard);
    expect(card.payment.reference, isNull);
    expect(card.payment.receivedCents, isNull);
    await fixture.provider.close();
  });
}

class _Fixture {
  _Fixture({
    required this.provider,
    required this.catalog,
    required this.tables,
    required this.orders,
    required this.payments,
    required this.transactions,
    required this.categoryRepository,
    required this.productRepository,
    required this.tableRepository,
    required this.orderRepository,
    required this.paymentRepository,
    required this.settings,
    required this.category,
    required this.product,
    required this.table,
  });

  final AppDatabase provider;
  final CatalogUseCases catalog;
  final TableUseCases tables;
  final OrderUseCases orders;
  final PaymentUseCases payments;
  final SqliteTransactionRunner transactions;
  final SqliteCategoryRepository categoryRepository;
  final SqliteProductRepository productRepository;
  final SqliteTableRepository tableRepository;
  final SqliteOrderRepository orderRepository;
  final SqlitePaymentRepository paymentRepository;
  final SqliteSettingsRepository settings;
  final Category category;
  final Product product;
  final CafeTable table;

  static Future<_Fixture> create(
    String databasePath,
    DateTime now, {
    IdGenerator ids = const _SequenceIdGenerator(),
  }) async {
    final AppDatabase provider = AppDatabase(databasePath: databasePath);
    await provider.initialize();
    final _Fixture base = await _build(provider, now, ids);
    final Category category = await base.catalog.createCategory('Bebidas');
    final Product product = await base.catalog.createProduct(
      categoryId: category.id,
      name: 'Café',
      price: '2.50',
    );
    final CafeTable table = await base.tables.createTable('Mesa 1');
    return _Fixture(
      provider: provider,
      catalog: base.catalog,
      tables: base.tables,
      orders: base.orders,
      payments: base.payments,
      transactions: base.transactions,
      categoryRepository: base.categoryRepository,
      productRepository: base.productRepository,
      tableRepository: base.tableRepository,
      orderRepository: base.orderRepository,
      paymentRepository: base.paymentRepository,
      settings: base.settings,
      category: category,
      product: product,
      table: table,
    );
  }

  static Future<_Fixture> openExisting(
    String databasePath,
    DateTime now,
  ) async {
    final AppDatabase provider = AppDatabase(databasePath: databasePath);
    await provider.initialize();
    final _Fixture base = await _build(
      provider,
      now,
      const _SequenceIdGenerator(100),
    );
    return _Fixture(
      provider: provider,
      catalog: base.catalog,
      tables: base.tables,
      orders: base.orders,
      payments: base.payments,
      transactions: base.transactions,
      categoryRepository: base.categoryRepository,
      productRepository: base.productRepository,
      tableRepository: base.tableRepository,
      orderRepository: base.orderRepository,
      paymentRepository: base.paymentRepository,
      settings: base.settings,
      category: (await base.categoryRepository.listAll()).single,
      product: (await base.productRepository.listAll()).single,
      table: (await base.tableRepository.listAll()).single,
    );
  }

  static Future<_Fixture> _build(
    AppDatabase provider,
    DateTime now,
    IdGenerator ids,
  ) async {
    final SqliteCategoryRepository categories = SqliteCategoryRepository(
      provider,
    );
    final SqliteProductRepository products = SqliteProductRepository(provider);
    final SqliteTableRepository tables = SqliteTableRepository(provider);
    final SqliteOrderRepository orders = SqliteOrderRepository(provider);
    final SqlitePaymentRepository payments = SqlitePaymentRepository(provider);
    final SqliteSettingsRepository settings = SqliteSettingsRepository(
      provider,
    );
    final SqliteTransactionRunner transactions = SqliteTransactionRunner(
      provider,
    );
    return _Fixture(
      provider: provider,
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
      transactions: transactions,
      categoryRepository: categories,
      productRepository: products,
      tableRepository: tables,
      orderRepository: orders,
      paymentRepository: payments,
      settings: settings,
      category: Category(
        id: '',
        name: '',
        sortOrder: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      product: Product(
        id: '',
        categoryId: '',
        name: '',
        priceCents: 0,
        isAvailable: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      table: CafeTable(
        id: '',
        name: '',
        sortOrder: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _SequenceIdGenerator implements IdGenerator {
  const _SequenceIdGenerator([this.start = 0]);

  final int start;
  static int _counter = 0;

  @override
  String generate() {
    _counter += 1;
    return '00000000-0000-4000-8000-${(start + _counter).toString().padLeft(12, '0')}';
  }
}

class _ConstantIdGenerator implements IdGenerator {
  const _ConstantIdGenerator(this.value);

  final String value;

  @override
  String generate() => value;
}
