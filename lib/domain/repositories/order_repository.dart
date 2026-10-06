import '../entities/order.dart';
import '../entities/order_details.dart';
import '../entities/order_item.dart';

abstract interface class OrderRepository {
  Future<List<Order>> listOpen();

  Future<OrderDetails?> findDetails(String id);

  Future<void> create(Order order);

  Future<void> insertItem(OrderItem item);

  Future<void> updateItem(OrderItem item);

  Future<void> removeItem(String orderId, String itemId);

  Future<void> updateTotal(String orderId, int totalCents, DateTime updatedAt);

  Future<void> cancel(String orderId, String reason, DateTime cancelledAt);

  Future<void> markPaid(String orderId, DateTime paidAt);
}
