import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/utc_date_range.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/report_repository.dart';
import '../database/app_database.dart';

class SqliteReportRepository implements ReportRepository {
  SqliteReportRepository(this._provider, this._cafeLocation);

  final AppDatabase _provider;
  final tz.Location _cafeLocation;

  @override
  Future<SalesReport> load(UtcDateRange paidRange) async {
    try {
      final Database database = await _provider.database;
      return await database.transaction<SalesReport>((
        Transaction transaction,
      ) async {
        final List<Object?> arguments = <Object?>[
          _timestamp(paidRange.start),
          _timestamp(paidRange.end),
        ];
        final List<Map<String, Object?>> paymentRows = await transaction
            .rawQuery('''
SELECT o.paid_at, p.method, p.amount_cents
FROM orders o
INNER JOIN payments p ON p.order_id = o.id
WHERE o.status = 'PAID'
  AND o.paid_at >= ?
  AND o.paid_at < ?
ORDER BY o.paid_at ASC
''', arguments);
        final List<Map<String, Object?>> itemRows = await transaction.rawQuery(
          '''
SELECT
  oi.product_name_snapshot,
  oi.category_name_snapshot,
  oi.quantity,
  oi.unit_price_cents
FROM orders o
INNER JOIN payments p ON p.order_id = o.id
INNER JOIN order_items oi ON oi.order_id = o.id
WHERE o.status = 'PAID'
  AND o.paid_at >= ?
  AND o.paid_at < ?
''',
          arguments,
        );
        return _aggregate(paymentRows, itemRows);
      });
    } on DatabaseException {
      throw const PersistenceError('No se pudo cargar el reporte de ventas.');
    }
  }

  SalesReport _aggregate(
    List<Map<String, Object?>> payments,
    List<Map<String, Object?>> items,
  ) {
    int netSalesCents = 0;
    final Map<PaymentMethod, int> byMethod = <PaymentMethod, int>{};
    final Map<int, int> byHour = <int, int>{};
    for (final Map<String, Object?> row in payments) {
      final int amount = row['amount_cents']! as int;
      final PaymentMethod method = _paymentMethodFromDatabase(
        row['method']! as String,
      );
      final int hour = tz.TZDateTime.from(
        DateTime.parse(row['paid_at']! as String),
        _cafeLocation,
      ).hour;
      netSalesCents += amount;
      byMethod.update(
        method,
        (int value) => value + amount,
        ifAbsent: () => amount,
      );
      byHour.update(
        hour,
        (int value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    int unitsSold = 0;
    final Map<String, int> byProduct = <String, int>{};
    final Map<String, int> byCategory = <String, int>{};
    for (final Map<String, Object?> row in items) {
      final int quantity = row['quantity']! as int;
      final int lineTotal = quantity * (row['unit_price_cents']! as int);
      final String product = row['product_name_snapshot']! as String;
      final String category = row['category_name_snapshot']! as String;
      unitsSold += quantity;
      byProduct.update(
        product,
        (int value) => value + quantity,
        ifAbsent: () => quantity,
      );
      byCategory.update(
        category,
        (int value) => value + lineTotal,
        ifAbsent: () => lineTotal,
      );
    }

    final List<ProductUnits> products =
        byProduct.entries
            .map((entry) => ProductUnits(name: entry.key, units: entry.value))
            .toList()
          ..sort((a, b) {
            final int units = b.units.compareTo(a.units);
            return units != 0 ? units : a.name.compareTo(b.name);
          });
    final List<NamedSalesTotal> categories = _namedTotals(byCategory);
    final List<HourlySalesTotal> hours =
        byHour.entries
            .map(
              (entry) =>
                  HourlySalesTotal(hour: entry.key, totalCents: entry.value),
            )
            .toList()
          ..sort((a, b) => a.hour.compareTo(b.hour));
    final List<PaymentMethodTotal> methods =
        byMethod.entries
            .map(
              (entry) => PaymentMethodTotal(
                method: entry.key,
                totalCents: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final int total = b.totalCents.compareTo(a.totalCents);
            return total != 0
                ? total
                : a.method.index.compareTo(b.method.index);
          });

    return SalesReport(
      netSalesCents: netSalesCents,
      paidOrderCount: payments.length,
      unitsSold: unitsSold,
      bestSellingProducts: products,
      salesByCategory: categories,
      salesByHour: hours,
      totalsByPaymentMethod: methods,
    );
  }

  List<NamedSalesTotal> _namedTotals(Map<String, int> values) {
    return values.entries
        .map(
          (entry) => NamedSalesTotal(name: entry.key, totalCents: entry.value),
        )
        .toList()
      ..sort((a, b) {
        final int total = b.totalCents.compareTo(a.totalCents);
        return total != 0 ? total : a.name.compareTo(b.name);
      });
  }
}

PaymentMethod _paymentMethodFromDatabase(String value) {
  return switch (value) {
    'CASH' => PaymentMethod.cash,
    'TRANSFER' => PaymentMethod.transfer,
    _ => PaymentMethod.creditCard,
  };
}

String _timestamp(DateTime value) => value.toUtc().toIso8601String();
