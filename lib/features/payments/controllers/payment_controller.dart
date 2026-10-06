import 'package:flutter/foundation.dart';

import '../../../application/use_cases/payment_use_cases.dart';
import '../../../domain/entities/order_details.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/errors/domain_error.dart';
import '../../../shared/money/money_parser.dart';

enum PaymentStatus { loading, ready, error }

class PaymentController extends ChangeNotifier {
  PaymentController(this._payments, this.orderId);

  final PaymentUseCases _payments;
  final String orderId;

  PaymentStatus status = PaymentStatus.loading;
  OrderDetails? details;
  PaymentMethod method = PaymentMethod.cash;
  bool manualConfirmed = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? receivedError;
  String? confirmationError;

  Future<void> load() async {
    status = PaymentStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      details = await _payments.loadOrder(orderId);
      status = PaymentStatus.ready;
    } on Object catch (error) {
      status = PaymentStatus.error;
      errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  void selectMethod(PaymentMethod value) {
    method = value;
    manualConfirmed = false;
    errorMessage = null;
    receivedError = null;
    confirmationError = null;
    notifyListeners();
  }

  void setManualConfirmed(bool value) {
    manualConfirmed = value;
    confirmationError = null;
    notifyListeners();
  }

  int? changeFor(String rawReceived) {
    if (method != PaymentMethod.cash || rawReceived.trim().isEmpty) {
      return null;
    }
    try {
      return parseReceivedCents(rawReceived) - details!.order.totalCents;
    } on ValidationError {
      return null;
    }
  }

  Future<PaymentResult?> submit({
    required String rawReceived,
    required String reference,
  }) async {
    if (isSubmitting) {
      return null;
    }
    errorMessage = null;
    receivedError = null;
    confirmationError = null;
    int? receivedCents;
    if (method == PaymentMethod.cash) {
      try {
        receivedCents = parseReceivedCents(rawReceived);
      } on ValidationError catch (error) {
        receivedError = error.message;
        notifyListeners();
        return null;
      }
    }

    isSubmitting = true;
    notifyListeners();
    try {
      return await _payments.pay(
        orderId: orderId,
        method: method,
        receivedCents: receivedCents,
        reference: reference,
        manualConfirmed: manualConfirmed,
      );
    } on ValidationError catch (error) {
      if (error.field == 'received') {
        receivedError = error.message;
      } else if (error.field == 'manualConfirmation') {
        confirmationError = error.message;
      } else {
        errorMessage = error.message;
      }
      return null;
    } on Object catch (error) {
      errorMessage = _messageFor(error);
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is DomainError) {
      return error.message;
    }
    return 'No se pudo completar el pago. Intenta nuevamente.';
  }
}
