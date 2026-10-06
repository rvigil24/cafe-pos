import 'package:sqflite/sqflite.dart';

import '../../domain/entities/payment.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/payment_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqlitePaymentRepository implements PaymentRepository {
  SqlitePaymentRepository(AppDatabase provider)
    : _executor = (() => provider.database);

  SqlitePaymentRepository.executor(DatabaseExecutor executor)
    : _executor = (() async => executor);

  final Future<DatabaseExecutor> Function() _executor;

  @override
  Future<Payment?> findByOrderId(String orderId) async {
    final DatabaseExecutor database = await _executor();
    final List<Map<String, Object?>> rows = await database.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: <Object?>[orderId],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> create(Payment payment) async {
    final DatabaseExecutor database = await _executor();
    final List<Map<String, Object?>> orderRows = await database.query(
      'orders',
      columns: <String>['status'],
      where: 'id = ?',
      whereArgs: <Object?>[payment.orderId],
      limit: 1,
    );
    if (orderRows.isEmpty) {
      throw const EntityNotFoundError('La orden ya no existe.');
    }
    if (orderRows.single['status'] != 'OPEN') {
      throw const PaymentNotAllowedError(
        'Solo se pueden pagar órdenes abiertas.',
      );
    }
    try {
      await database.insert('payments', _toRow(payment));
    } on DatabaseException catch (error) {
      if (error.toString().toLowerCase().contains('payments.order_id')) {
        throw const DuplicatePaymentError('La orden ya fue pagada.');
      }
      translateDatabaseError(error, 'No se pudo guardar el pago.');
    }
  }

  Payment _fromRow(Map<String, Object?> row) {
    return Payment(
      id: row['id']! as String,
      orderId: row['order_id']! as String,
      method: switch (row['method']) {
        'CASH' => PaymentMethod.cash,
        'TRANSFER' => PaymentMethod.transfer,
        _ => PaymentMethod.creditCard,
      },
      amountCents: row['amount_cents']! as int,
      receivedCents: row['received_cents'] as int?,
      reference: row['reference'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String),
    );
  }

  Map<String, Object?> _toRow(Payment payment) {
    return <String, Object?>{
      'id': payment.id,
      'order_id': payment.orderId,
      'method': switch (payment.method) {
        PaymentMethod.cash => 'CASH',
        PaymentMethod.transfer => 'TRANSFER',
        PaymentMethod.creditCard => 'CREDIT_CARD',
      },
      'amount_cents': payment.amountCents,
      'received_cents': payment.receivedCents,
      'reference': payment.reference,
      'created_at': timestamp(payment.createdAt),
    };
  }
}
