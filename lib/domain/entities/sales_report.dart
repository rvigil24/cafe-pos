import 'payment.dart';

class ProductUnits {
  const ProductUnits({required this.name, required this.units});

  final String name;
  final int units;
}

class NamedSalesTotal {
  const NamedSalesTotal({required this.name, required this.totalCents});

  final String name;
  final int totalCents;
}

class HourlySalesTotal {
  const HourlySalesTotal({required this.hour, required this.totalCents});

  final int hour;
  final int totalCents;
}

class PaymentMethodTotal {
  const PaymentMethodTotal({required this.method, required this.totalCents});

  final PaymentMethod method;
  final int totalCents;
}

class SalesReport {
  const SalesReport({
    required this.netSalesCents,
    required this.paidOrderCount,
    required this.unitsSold,
    required this.bestSellingProducts,
    required this.salesByCategory,
    required this.salesByHour,
    required this.totalsByPaymentMethod,
  });

  final int netSalesCents;
  final int paidOrderCount;
  final int unitsSold;
  final List<ProductUnits> bestSellingProducts;
  final List<NamedSalesTotal> salesByCategory;
  final List<HourlySalesTotal> salesByHour;
  final List<PaymentMethodTotal> totalsByPaymentMethod;

  int get averageTicketCents {
    if (paidOrderCount == 0) {
      return 0;
    }
    return (netSalesCents + paidOrderCount ~/ 2) ~/ paidOrderCount;
  }
}
