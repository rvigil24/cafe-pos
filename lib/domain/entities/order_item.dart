class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productNameSnapshot,
    required this.categoryNameSnapshot,
    required this.quantity,
    required this.unitPriceCents,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderId;
  final String? productId;
  final String productNameSnapshot;
  final String categoryNameSnapshot;
  final int quantity;
  final int unitPriceCents;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get totalCents => quantity * unitPriceCents;

  OrderItem copyWith({
    int? quantity,
    String? note,
    bool clearNote = false,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      productNameSnapshot: productNameSnapshot,
      categoryNameSnapshot: categoryNameSnapshot,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents,
      note: clearNote ? null : note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
