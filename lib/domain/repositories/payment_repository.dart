import '../entities/payment.dart';

abstract interface class PaymentRepository {
  Future<Payment?> findByOrderId(String orderId);

  Future<void> create(Payment payment);
}
