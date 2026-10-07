import '../entities/payment.dart';
import '../entities/sale.dart';
import '../entities/utc_date_range.dart';

abstract interface class SalesRepository {
  Future<List<SaleSummary>> list({
    int? orderNumber,
    UtcDateRange? paidRange,
    PaymentMethod? paymentMethod,
  });

  Future<SaleDetails?> findDetails(String orderId);
}
