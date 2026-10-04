import 'order.dart';
import 'order_item.dart';

class OrderDetails {
  const OrderDetails({required this.order, required this.items});

  final Order order;
  final List<OrderItem> items;
}
