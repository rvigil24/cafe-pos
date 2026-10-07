import 'dart:io';

import 'package:cafe_pos/application/services/id_generator.dart';
import 'package:cafe_pos/application/use_cases/payment_use_cases.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/domain/entities/utc_date_range.dart';
import 'package:cafe_pos/infrastructure/database/app_database.dart';
import 'package:cafe_pos/infrastructure/database/sqlite_transaction_runner.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_order_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_report_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_sales_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String databasePath;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    final Directory directory = await getTemporaryDirectory();
    databasePath = path.join(directory.path, 'history_reports_test.db');
    await deleteDatabase(databasePath);
  });

  tearDown(() => deleteDatabase(databasePath));

  testWidgets('history filters and report totals use paid_at and snapshots', (
    WidgetTester tester,
  ) async {
    final AppDatabase provider = AppDatabase(databasePath: databasePath);
    final Database database = await provider.initialize();
    await _insertFixture(database);
    final SqliteSalesRepository sales = SqliteSalesRepository(provider);
    final SqliteReportRepository reports = SqliteReportRepository(
      provider,
      tz.getLocation('America/El_Salvador'),
    );
    final UtcDateRange octoberSix = UtcDateRange(
      start: DateTime.utc(2026, 10, 6, 6),
      end: DateTime.utc(2026, 10, 7, 6),
    );

    final history = await sales.list(paidRange: octoberSix);
    expect(history.map((sale) => sale.orderNumber), <int>[2, 1]);
    expect(history.first.paidAt, DateTime.utc(2026, 10, 6, 20));
    expect(
      (await sales.list(
        paidRange: octoberSix,
        paymentMethod: PaymentMethod.cash,
      )).single.orderNumber,
      1,
    );
    expect(
      (await sales.list(orderNumber: 2)).single.paymentMethod,
      PaymentMethod.transfer,
    );

    final details = await sales.findDetails('order-1');
    expect(details!.sale.tableNameSnapshot, 'Terraza histórica');
    expect(details.items, hasLength(2));
    expect(details.items.first.note, 'Sin azúcar');
    expect(details.payment.receivedCents, 1200);
    expect(details.payment.changeCents, 200);

    final report = await reports.load(octoberSix);
    expect(report.netSalesCents, 1500);
    expect(report.paidOrderCount, 2);
    expect(report.averageTicketCents, 750);
    expect(report.unitsSold, 6);
    expect(report.bestSellingProducts.first.name, 'Café');
    expect(report.bestSellingProducts.first.units, 5);
    expect(report.salesByCategory.first.name, 'Bebidas históricas');
    expect(report.salesByCategory.first.totalCents, 1300);
    expect(
      report.salesByHour.map((value) => (value.hour, value.totalCents)),
      <(int, int)>[(1, 1000), (14, 500)],
    );
    expect(
      report.totalsByPaymentMethod.map(
        (value) => (value.method, value.totalCents),
      ),
      <(PaymentMethod, int)>[
        (PaymentMethod.cash, 1000),
        (PaymentMethod.transfer, 500),
      ],
    );

    final DateTime newPaidAt = DateTime.utc(2026, 10, 6, 22);
    await database.insert('orders', <String, Object?>{
      'id': 'new-order',
      'order_number': 6,
      'type': 'TAKEAWAY',
      'status': 'OPEN',
      'total_cents': 250,
      'created_at': newPaidAt.toIso8601String(),
      'updated_at': newPaidAt.toIso8601String(),
    });
    await _insertItem(
      database,
      id: 'new-item',
      orderId: 'new-order',
      product: 'Té',
      category: 'Bebidas históricas',
      quantity: 1,
      price: 250,
    );
    final PaymentUseCases payments = PaymentUseCases(
      orders: SqliteOrderRepository(provider),
      transactions: SqliteTransactionRunner(provider),
      ids: const UuidIdGenerator(),
      clock: () => newPaidAt,
    );
    await payments.pay(
      orderId: 'new-order',
      method: PaymentMethod.creditCard,
      manualConfirmed: true,
    );

    final newSale = (await sales.list(orderNumber: 6)).single;
    expect(newSale.paidAt, newPaidAt);
    expect(newSale.paymentMethod, PaymentMethod.creditCard);
    final refreshedReport = await reports.load(octoberSix);
    expect(refreshedReport.netSalesCents, 1750);
    expect(refreshedReport.paidOrderCount, 3);
    expect(refreshedReport.unitsSold, 7);
    expect(
      refreshedReport.totalsByPaymentMethod
          .singleWhere((value) => value.method == PaymentMethod.creditCard)
          .totalCents,
      250,
    );

    await provider.close();
  });
}

Future<void> _insertFixture(Database database) async {
  final String createdOutsideRange = DateTime.utc(
    2026,
    9,
    20,
    12,
  ).toIso8601String();
  await database.insert('cafe_tables', <String, Object?>{
    'id': 'table-1',
    'name': 'Terraza actual',
    'sort_order': 0,
    'is_active': 1,
    'created_at': createdOutsideRange,
    'updated_at': createdOutsideRange,
  });
  await _insertPaidOrder(
    database,
    id: 'order-1',
    number: 1,
    total: 1000,
    paidAt: DateTime.utc(2026, 10, 6, 7),
    method: 'CASH',
    tableId: 'table-1',
    tableSnapshot: 'Terraza histórica',
    received: 1200,
    createdAt: createdOutsideRange,
  );
  await _insertItem(
    database,
    id: 'item-1',
    orderId: 'order-1',
    product: 'Café',
    category: 'Bebidas históricas',
    quantity: 4,
    price: 200,
    note: 'Sin azúcar',
  );
  await _insertItem(
    database,
    id: 'item-2',
    orderId: 'order-1',
    product: 'Pan',
    category: 'Comida histórica',
    quantity: 1,
    price: 200,
  );
  await _insertPaidOrder(
    database,
    id: 'order-2',
    number: 2,
    total: 500,
    paidAt: DateTime.utc(2026, 10, 6, 20),
    method: 'TRANSFER',
    reference: 'TR-2',
    createdAt: createdOutsideRange,
  );
  await _insertItem(
    database,
    id: 'item-3',
    orderId: 'order-2',
    product: 'Café',
    category: 'Bebidas históricas',
    quantity: 1,
    price: 500,
  );
  await _insertPaidOrder(
    database,
    id: 'order-boundary',
    number: 3,
    total: 300,
    paidAt: DateTime.utc(2026, 10, 7, 6),
    method: 'CREDIT_CARD',
    createdAt: createdOutsideRange,
  );
  await _insertItem(
    database,
    id: 'item-boundary',
    orderId: 'order-boundary',
    product: 'Té',
    category: 'Bebidas históricas',
    quantity: 1,
    price: 300,
  );
  await database.insert('orders', <String, Object?>{
    'id': 'open-order',
    'order_number': 4,
    'type': 'TAKEAWAY',
    'status': 'OPEN',
    'total_cents': 999,
    'created_at': DateTime.utc(2026, 10, 6, 12).toIso8601String(),
    'updated_at': DateTime.utc(2026, 10, 6, 12).toIso8601String(),
  });
  await database.insert('orders', <String, Object?>{
    'id': 'cancelled-order',
    'order_number': 5,
    'type': 'TAKEAWAY',
    'status': 'CANCELLED',
    'total_cents': 999,
    'created_at': DateTime.utc(2026, 10, 6, 12).toIso8601String(),
    'updated_at': DateTime.utc(2026, 10, 6, 13).toIso8601String(),
    'cancelled_at': DateTime.utc(2026, 10, 6, 13).toIso8601String(),
    'cancellation_reason': 'Fixture',
  });
}

Future<void> _insertPaidOrder(
  Database database, {
  required String id,
  required int number,
  required int total,
  required DateTime paidAt,
  required String method,
  required String createdAt,
  String? tableId,
  String? tableSnapshot,
  int? received,
  String? reference,
}) async {
  final bool dineIn = tableId != null;
  await database.insert('orders', <String, Object?>{
    'id': id,
    'order_number': number,
    'table_id': tableId,
    'table_name_snapshot': tableSnapshot,
    'type': dineIn ? 'DINE_IN' : 'TAKEAWAY',
    'status': 'PAID',
    'total_cents': total,
    'created_at': createdAt,
    'updated_at': paidAt.toIso8601String(),
    'paid_at': paidAt.toIso8601String(),
  });
  await database.insert('payments', <String, Object?>{
    'id': 'payment-$id',
    'order_id': id,
    'method': method,
    'amount_cents': total,
    'received_cents': received,
    'reference': reference,
    'created_at': paidAt.toIso8601String(),
  });
}

Future<void> _insertItem(
  Database database, {
  required String id,
  required String orderId,
  required String product,
  required String category,
  required int quantity,
  required int price,
  String? note,
}) async {
  final String timestamp = DateTime.utc(2026, 10, 6, 7).toIso8601String();
  await database.insert('order_items', <String, Object?>{
    'id': id,
    'order_id': orderId,
    'product_name_snapshot': product,
    'category_name_snapshot': category,
    'quantity': quantity,
    'unit_price_cents': price,
    'note': note,
    'created_at': timestamp,
    'updated_at': timestamp,
  });
}
