enum OrderType { dineIn, takeaway }

enum OrderStatus { open, paid, cancelled }

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.tableId,
    required this.tableNameSnapshot,
    required this.type,
    required this.status,
    required this.totalCents,
    required this.createdAt,
    required this.updatedAt,
    required this.paidAt,
    required this.cancelledAt,
    required this.cancellationReason,
  });

  final String id;
  final int orderNumber;
  final String? tableId;
  final String? tableNameSnapshot;
  final OrderType type;
  final OrderStatus status;
  final int totalCents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  Order copyWith({
    int? totalCents,
    OrderStatus? status,
    DateTime? updatedAt,
    DateTime? paidAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      tableId: tableId,
      tableNameSnapshot: tableNameSnapshot,
      type: type,
      status: status ?? this.status,
      totalCents: totalCents ?? this.totalCents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
