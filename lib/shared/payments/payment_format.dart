import '../../domain/entities/payment.dart';

String paymentMethodLabel(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => 'Efectivo',
    PaymentMethod.transfer => 'Transferencia',
    PaymentMethod.creditCard => 'Tarjeta',
  };
}
