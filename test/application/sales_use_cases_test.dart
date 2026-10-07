import 'package:cafe_pos/application/services/cafe_calendar.dart';
import 'package:cafe_pos/application/use_cases/sales_use_cases.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/domain/entities/sale.dart';
import 'package:cafe_pos/domain/entities/utc_date_range.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/domain/repositories/sales_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late _RecordingSalesRepository repository;
  late SalesUseCases useCases;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    repository = _RecordingSalesRepository();
    useCases = SalesUseCases(
      sales: repository,
      calendar: CafeCalendar(tz.getLocation('America/El_Salvador')),
    );
  });

  test('parses exact order number and inclusive local dates', () async {
    await useCases.search(
      orderNumber: ' 42 ',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 1),
      paymentMethod: PaymentMethod.transfer,
    );

    expect(repository.orderNumber, 42);
    expect(repository.paymentMethod, PaymentMethod.transfer);
    expect(repository.range?.start, DateTime.utc(2026, 10, 1, 6));
    expect(repository.range?.end, DateTime.utc(2026, 10, 2, 6));
  });

  test('rejects an invalid order number before querying', () {
    expect(
      () => useCases.search(orderNumber: '12a'),
      throwsA(isA<ValidationError>()),
    );
    expect(repository.calls, 0);
  });

  test('reports a missing sale as a typed error', () {
    expect(
      () => useCases.loadDetails('missing'),
      throwsA(isA<EntityNotFoundError>()),
    );
  });
}

class _RecordingSalesRepository implements SalesRepository {
  int calls = 0;
  int? orderNumber;
  UtcDateRange? range;
  PaymentMethod? paymentMethod;

  @override
  Future<SaleDetails?> findDetails(String orderId) async => null;

  @override
  Future<List<SaleSummary>> list({
    int? orderNumber,
    UtcDateRange? paidRange,
    PaymentMethod? paymentMethod,
  }) async {
    calls += 1;
    this.orderNumber = orderNumber;
    range = paidRange;
    this.paymentMethod = paymentMethod;
    return <SaleSummary>[];
  }
}
