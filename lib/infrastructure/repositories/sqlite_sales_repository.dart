import 'package:sqflite/sqflite.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/utc_date_range.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/sales_repository.dart';
import '../database/app_database.dart';

class SqliteSalesRepository implements SalesRepository {
  SqliteSalesRepository(this._provider);

  final AppDatabase _provider;

  @override
  Future<List<SaleSummary>> list({
    int? orderNumber,
    UtcDateRange? paidRange,
    PaymentMethod? paymentMethod,
  }) async {
    try {
      final Database database = await _provider.database;
      final List<String> clauses = <String>[
        "o.status = 'PAID'",
        'o.paid_at IS NOT NULL',
      ];
      final List<Object?> arguments = <Object?>[];
      if (orderNumber != null) {
        clauses.add('o.order_number = ?');
        arguments.add(orderNumber);
      }
      if (paidRange != null) {
        clauses.add('o.paid_at >= ? AND o.paid_at < ?');
        arguments
          ..add(_timestamp(paidRange.start))
          ..add(_timestamp(paidRange.end));
      }
      if (paymentMethod != null) {
        clauses.add('p.method = ?');
        arguments.add(_paymentMethodToDatabase(paymentMethod));
      }
      final List<Map<String, Object?>> rows = await database.rawQuery('''
SELECT
  o.id,
  o.order_number,
  o.type,
  o.table_name_snapshot,
  o.total_cents,
  o.paid_at,
  p.method
FROM orders o
INNER JOIN payments p ON p.order_id = o.id
WHERE ${clauses.join(' AND ')}
ORDER BY o.paid_at DESC, o.order_number DESC
''', arguments);
      return rows.map(_saleFromRow).toList(growable: false);
    } on DatabaseException {
      throw const PersistenceError('No se pudo cargar el historial de ventas.');
    }
  }

  @override
  Future<SaleDetails?> findDetails(String orderId) async {
    try {
      final Database database = await _provider.database;
      return await database.transaction<SaleDetails?>((
        Transaction transaction,
      ) async {
        final List<Map<String, Object?>> saleRows = await transaction.rawQuery(
          '''
SELECT
  o.id,
  o.order_number,
  o.type,
  o.table_name_snapshot,
  o.total_cents,
  o.paid_at,
  p.method,
  p.id AS payment_id,
  p.amount_cents,
  p.received_cents,
  p.reference,
  p.created_at AS payment_created_at
FROM orders o
INNER JOIN payments p ON p.order_id = o.id
WHERE o.id = ? AND o.status = 'PAID' AND o.paid_at IS NOT NULL
LIMIT 1
''',
          <Object?>[orderId],
        );
        if (saleRows.isEmpty) {
          return null;
        }
        final Map<String, Object?> saleRow = saleRows.single;
        final List<Map<String, Object?>> itemRows = await transaction.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: <Object?>[orderId],
          orderBy: 'created_at ASC, id ASC',
        );
        return SaleDetails(
          sale: _saleFromRow(saleRow),
          items: itemRows.map(_itemFromRow).toList(growable: false),
          payment: Payment(
            id: saleRow['payment_id']! as String,
            orderId: orderId,
            method: _paymentMethodFromDatabase(saleRow['method']! as String),
            amountCents: saleRow['amount_cents']! as int,
            receivedCents: saleRow['received_cents'] as int?,
            reference: saleRow['reference'] as String?,
            createdAt: DateTime.parse(saleRow['payment_created_at']! as String),
          ),
        );
      });
    } on DatabaseException {
      throw const PersistenceError('No se pudo cargar el detalle de la venta.');
    }
  }

  SaleSummary _saleFromRow(Map<String, Object?> row) {
    return SaleSummary(
      orderId: row['id']! as String,
      orderNumber: row['order_number']! as int,
      type: row['type'] == 'DINE_IN' ? OrderType.dineIn : OrderType.takeaway,
      tableNameSnapshot: row['table_name_snapshot'] as String?,
      totalCents: row['total_cents']! as int,
      paidAt: DateTime.parse(row['paid_at']! as String),
      paymentMethod: _paymentMethodFromDatabase(row['method']! as String),
    );
  }

  OrderItem _itemFromRow(Map<String, Object?> row) {
    return OrderItem(
      id: row['id']! as String,
      orderId: row['order_id']! as String,
      productId: row['product_id'] as String?,
      productNameSnapshot: row['product_name_snapshot']! as String,
      categoryNameSnapshot: row['category_name_snapshot']! as String,
      quantity: row['quantity']! as int,
      unitPriceCents: row['unit_price_cents']! as int,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}

PaymentMethod _paymentMethodFromDatabase(String value) {
  return switch (value) {
    'CASH' => PaymentMethod.cash,
    'TRANSFER' => PaymentMethod.transfer,
    _ => PaymentMethod.creditCard,
  };
}

String _paymentMethodToDatabase(PaymentMethod value) {
  return switch (value) {
    PaymentMethod.cash => 'CASH',
    PaymentMethod.transfer => 'TRANSFER',
    PaymentMethod.creditCard => 'CREDIT_CARD',
  };
}

String _timestamp(DateTime value) => value.toUtc().toIso8601String();
