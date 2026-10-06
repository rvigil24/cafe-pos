import '../../domain/entities/order.dart';
import '../../domain/entities/order_details.dart';
import '../../domain/entities/payment.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/order_repository.dart';
import '../services/id_generator.dart';
import '../services/transaction_runner.dart';

typedef PaymentClock = DateTime Function();

class PaymentResult {
  const PaymentResult({required this.payment});

  final Payment payment;

  int? get changeCents => payment.changeCents;
}

class PaymentUseCases {
  const PaymentUseCases({
    required OrderRepository orders,
    required TransactionRunner transactions,
    required IdGenerator ids,
    required PaymentClock clock,
  }) : this._(orders, transactions, ids, clock);

  const PaymentUseCases._(
    this._orders,
    this._transactions,
    this._ids,
    this._clock,
  );

  final OrderRepository _orders;
  final TransactionRunner _transactions;
  final IdGenerator _ids;
  final PaymentClock _clock;

  Future<OrderDetails> loadOrder(String orderId) async {
    final OrderDetails? details = await _orders.findDetails(orderId);
    if (details == null) {
      throw const EntityNotFoundError('La orden ya no existe.');
    }
    return details;
  }

  Future<PaymentResult> pay({
    required String orderId,
    required PaymentMethod method,
    int? receivedCents,
    String? reference,
    bool manualConfirmed = false,
  }) {
    return _transactions.run<PaymentResult>((TransactionRepositories tx) async {
      final OrderDetails? details = await tx.orders.findDetails(orderId);
      if (details == null) {
        throw const EntityNotFoundError('La orden ya no existe.');
      }
      if (await tx.payments.findByOrderId(orderId) != null) {
        throw const DuplicatePaymentError('La orden ya fue pagada.');
      }
      if (details.order.status != OrderStatus.open) {
        throw const PaymentNotAllowedError(
          'Solo se pueden pagar órdenes abiertas.',
        );
      }
      if (details.items.isEmpty) {
        throw const PaymentNotAllowedError(
          'Agrega al menos un producto antes de cobrar.',
        );
      }

      final int totalCents = details.items.fold<int>(
        0,
        (int total, item) => total + item.totalCents,
      );
      if (method == PaymentMethod.cash) {
        if (receivedCents == null) {
          throw const ValidationError(
            'Ingresa el monto recibido.',
            field: 'received',
          );
        }
        if (receivedCents < totalCents) {
          throw const ValidationError(
            'El monto recibido debe cubrir el total.',
            field: 'received',
          );
        }
      } else if (!manualConfirmed) {
        throw const ValidationError(
          'Confirma que el pago fue verificado manualmente.',
          field: 'manualConfirmation',
        );
      }

      final DateTime now = _clock().toUtc();
      if (details.order.totalCents != totalCents) {
        await tx.orders.updateTotal(orderId, totalCents, now);
      }
      final String trimmedReference = (reference ?? '').trim();
      final Payment payment = Payment(
        id: _ids.generate(),
        orderId: orderId,
        method: method,
        amountCents: totalCents,
        receivedCents: method == PaymentMethod.cash ? receivedCents : null,
        reference: method != PaymentMethod.transfer || trimmedReference.isEmpty
            ? null
            : trimmedReference,
        createdAt: now,
      );
      await tx.payments.create(payment);
      await tx.orders.markPaid(orderId, now);
      return PaymentResult(payment: payment);
    });
  }
}
