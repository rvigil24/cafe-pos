import 'package:sqflite/sqflite.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_details.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/order_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqliteOrderRepository implements OrderRepository {
  SqliteOrderRepository(AppDatabase provider)
    : _executor = (() => provider.database);

  SqliteOrderRepository.executor(DatabaseExecutor executor)
    : _executor = (() async => executor);

  final Future<DatabaseExecutor> Function() _executor;

  @override
  Future<List<Order>> listOpen() async {
    final DatabaseExecutor database = await _executor();
    final List<Map<String, Object?>> rows = await database.query(
      'orders',
      where: 'status = ?',
      whereArgs: <Object?>['OPEN'],
      orderBy: 'created_at ASC',
    );
    return rows.map(_orderFromRow).toList(growable: false);
  }

  @override
  Future<OrderDetails?> findDetails(String id) async {
    final DatabaseExecutor database = await _executor();
    final List<Map<String, Object?>> orderRows = await database.query(
      'orders',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (orderRows.isEmpty) {
      return null;
    }
    final List<Map<String, Object?>> itemRows = await database.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: <Object?>[id],
      orderBy: 'created_at ASC, id ASC',
    );
    return OrderDetails(
      order: _orderFromRow(orderRows.single),
      items: itemRows.map(_itemFromRow).toList(growable: false),
    );
  }

  @override
  Future<void> create(Order order) async {
    try {
      final DatabaseExecutor database = await _executor();
      await database.insert('orders', _orderToRow(order));
    } on DatabaseException catch (error) {
      final String message = error.toString().toLowerCase();
      if (message.contains('orders.table_id')) {
        throw const TableUnavailableError(
          'La mesa ya tiene una orden abierta.',
        );
      }
      throw const PersistenceError('No se pudo crear la orden.');
    }
  }

  @override
  Future<void> insertItem(OrderItem item) async {
    final DatabaseExecutor database = await _executor();
    await _requireOpen(database, item.orderId);
    try {
      await database.insert('order_items', _itemToRow(item));
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo agregar el producto.');
    }
  }

  @override
  Future<void> updateItem(OrderItem item) async {
    final DatabaseExecutor database = await _executor();
    final int count = await database.update(
      'order_items',
      <String, Object?>{
        'quantity': item.quantity,
        'note': item.note,
        'updated_at': timestamp(item.updatedAt),
      },
      where:
          'id = ? AND order_id = ? AND EXISTS ('
          "SELECT 1 FROM orders WHERE id = ? AND status = 'OPEN'"
          ')',
      whereArgs: <Object?>[item.id, item.orderId, item.orderId],
    );
    if (count != 1) {
      await _throwMissingItemOrClosed(database, item.orderId, item.id);
    }
  }

  @override
  Future<void> removeItem(String orderId, String itemId) async {
    final DatabaseExecutor database = await _executor();
    final int count = await database.delete(
      'order_items',
      where:
          'id = ? AND order_id = ? AND EXISTS ('
          "SELECT 1 FROM orders WHERE id = ? AND status = 'OPEN'"
          ')',
      whereArgs: <Object?>[itemId, orderId, orderId],
    );
    if (count != 1) {
      await _throwMissingItemOrClosed(database, orderId, itemId);
    }
  }

  @override
  Future<void> updateTotal(
    String orderId,
    int totalCents,
    DateTime updatedAt,
  ) async {
    final DatabaseExecutor database = await _executor();
    final int count = await database.update(
      'orders',
      <String, Object?>{
        'total_cents': totalCents,
        'updated_at': timestamp(updatedAt),
      },
      where: "id = ? AND status = 'OPEN'",
      whereArgs: <Object?>[orderId],
    );
    if (count != 1) {
      await _requireOpen(database, orderId);
    }
  }

  @override
  Future<void> cancel(
    String orderId,
    String reason,
    DateTime cancelledAt,
  ) async {
    final DatabaseExecutor database = await _executor();
    final int count = await database.update(
      'orders',
      <String, Object?>{
        'status': 'CANCELLED',
        'updated_at': timestamp(cancelledAt),
        'cancelled_at': timestamp(cancelledAt),
        'cancellation_reason': reason,
      },
      where: "id = ? AND status = 'OPEN'",
      whereArgs: <Object?>[orderId],
    );
    if (count != 1) {
      await _requireOpen(database, orderId);
    }
  }

  @override
  Future<void> markPaid(String orderId, DateTime paidAt) async {
    final DatabaseExecutor database = await _executor();
    try {
      final int count = await database.update(
        'orders',
        <String, Object?>{
          'status': 'PAID',
          'updated_at': timestamp(paidAt),
          'paid_at': timestamp(paidAt),
        },
        where:
            "id = ? AND status = 'OPEN' AND EXISTS ("
            'SELECT 1 FROM payments WHERE order_id = ?'
            ')',
        whereArgs: <Object?>[orderId, orderId],
      );
      if (count != 1) {
        await _requireOpen(database, orderId);
        throw const PersistenceError('No se pudo completar el pago.');
      }
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo completar el pago.');
    }
  }

  Future<void> _requireOpen(DatabaseExecutor database, String orderId) async {
    final List<Map<String, Object?>> rows = await database.query(
      'orders',
      columns: <String>['status'],
      where: 'id = ?',
      whereArgs: <Object?>[orderId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const EntityNotFoundError('La orden ya no existe.');
    }
    if (rows.single['status'] != 'OPEN') {
      throw const OrderNotEditableError(
        'Solo se pueden modificar órdenes abiertas.',
      );
    }
  }

  Future<void> _throwMissingItemOrClosed(
    DatabaseExecutor database,
    String orderId,
    String itemId,
  ) async {
    await _requireOpen(database, orderId);
    final List<Map<String, Object?>> rows = await database.query(
      'order_items',
      columns: <String>['id'],
      where: 'id = ? AND order_id = ?',
      whereArgs: <Object?>[itemId, orderId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const EntityNotFoundError('El producto ya no está en la orden.');
    }
    throw const PersistenceError('No se pudo guardar la orden.');
  }

  Order _orderFromRow(Map<String, Object?> row) {
    return Order(
      id: row['id']! as String,
      orderNumber: row['order_number']! as int,
      tableId: row['table_id'] as String?,
      tableNameSnapshot: row['table_name_snapshot'] as String?,
      type: row['type'] == 'DINE_IN' ? OrderType.dineIn : OrderType.takeaway,
      status: switch (row['status']) {
        'OPEN' => OrderStatus.open,
        'PAID' => OrderStatus.paid,
        _ => OrderStatus.cancelled,
      },
      totalCents: row['total_cents']! as int,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      paidAt: _optionalDate(row['paid_at']),
      cancelledAt: _optionalDate(row['cancelled_at']),
      cancellationReason: row['cancellation_reason'] as String?,
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

  Map<String, Object?> _orderToRow(Order order) {
    return <String, Object?>{
      'id': order.id,
      'order_number': order.orderNumber,
      'table_id': order.tableId,
      'table_name_snapshot': order.tableNameSnapshot,
      'type': order.type == OrderType.dineIn ? 'DINE_IN' : 'TAKEAWAY',
      'status': switch (order.status) {
        OrderStatus.open => 'OPEN',
        OrderStatus.paid => 'PAID',
        OrderStatus.cancelled => 'CANCELLED',
      },
      'total_cents': order.totalCents,
      'created_at': timestamp(order.createdAt),
      'updated_at': timestamp(order.updatedAt),
      'paid_at': order.paidAt == null ? null : timestamp(order.paidAt!),
      'cancelled_at': order.cancelledAt == null
          ? null
          : timestamp(order.cancelledAt!),
      'cancellation_reason': order.cancellationReason,
    };
  }

  Map<String, Object?> _itemToRow(OrderItem item) {
    return <String, Object?>{
      'id': item.id,
      'order_id': item.orderId,
      'product_id': item.productId,
      'product_name_snapshot': item.productNameSnapshot,
      'category_name_snapshot': item.categoryNameSnapshot,
      'quantity': item.quantity,
      'unit_price_cents': item.unitPriceCents,
      'note': item.note,
      'created_at': timestamp(item.createdAt),
      'updated_at': timestamp(item.updatedAt),
    };
  }

  DateTime? _optionalDate(Object? value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}
