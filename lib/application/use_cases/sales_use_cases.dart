import '../../domain/entities/payment.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/utc_date_range.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/sales_repository.dart';
import '../services/cafe_calendar.dart';

class SalesUseCases {
  const SalesUseCases({
    required SalesRepository sales,
    required CafeCalendar calendar,
  }) : this._(sales, calendar);

  const SalesUseCases._(this._sales, this._calendar);

  final SalesRepository _sales;
  final CafeCalendar _calendar;

  Future<List<SaleSummary>> search({
    String orderNumber = '',
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
  }) {
    final String trimmed = orderNumber.trim();
    final int? parsedOrderNumber = trimmed.isEmpty
        ? null
        : int.tryParse(trimmed);
    if (trimmed.isNotEmpty &&
        (parsedOrderNumber == null || parsedOrderNumber <= 0)) {
      throw const ValidationError(
        'Ingresa un número de orden válido.',
        field: 'orderNumber',
      );
    }
    UtcDateRange? range;
    if (startDate != null || endDate != null) {
      range = _calendar.inclusiveDateRange(startDate, endDate);
    }
    return _sales.list(
      orderNumber: parsedOrderNumber,
      paidRange: range,
      paymentMethod: paymentMethod,
    );
  }

  Future<SaleDetails> loadDetails(String orderId) async {
    final SaleDetails? details = await _sales.findDetails(orderId);
    if (details == null) {
      throw const EntityNotFoundError('La venta ya no existe.');
    }
    return details;
  }
}
