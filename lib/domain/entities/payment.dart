enum PaymentMethod { cash, transfer, creditCard }

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amountCents,
    required this.receivedCents,
    required this.reference,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final PaymentMethod method;
  final int amountCents;
  final int? receivedCents;
  final String? reference;
  final DateTime createdAt;

  int? get changeCents => switch (receivedCents) {
    final int received => received - amountCents,
    null => null,
  };
}
