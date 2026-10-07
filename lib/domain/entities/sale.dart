import 'order.dart';
import 'order_item.dart';
import 'payment.dart';

class SaleSummary {
  const SaleSummary({
    required this.orderId,
    required this.orderNumber,
    required this.type,
    required this.tableNameSnapshot,
    required this.totalCents,
    required this.paidAt,
    required this.paymentMethod,
  });

  final String orderId;
  final int orderNumber;
  final OrderType type;
  final String? tableNameSnapshot;
  final int totalCents;
  final DateTime paidAt;
  final PaymentMethod paymentMethod;
}

class SaleDetails {
  const SaleDetails({
    required this.sale,
    required this.items,
    required this.payment,
  });

  final SaleSummary sale;
  final List<OrderItem> items;
  final Payment payment;
}
