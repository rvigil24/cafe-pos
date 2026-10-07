import 'package:cafe_pos/application/services/id_generator.dart';
import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/domain/entities/app_settings.dart';
import 'package:cafe_pos/domain/entities/cafe_table.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/order.dart';
import 'package:cafe_pos/domain/entities/order_details.dart';
import 'package:cafe_pos/domain/entities/order_item.dart';
import 'package:cafe_pos/domain/entities/payment.dart';
import 'package:cafe_pos/domain/entities/product.dart';
import 'package:cafe_pos/domain/entities/sale.dart';
import 'package:cafe_pos/domain/entities/sales_report.dart';
import 'package:cafe_pos/domain/entities/utc_date_range.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/domain/repositories/category_repository.dart';
import 'package:cafe_pos/domain/repositories/order_repository.dart';
import 'package:cafe_pos/domain/repositories/payment_repository.dart';
import 'package:cafe_pos/domain/repositories/product_repository.dart';
import 'package:cafe_pos/domain/repositories/report_repository.dart';
import 'package:cafe_pos/domain/repositories/sales_repository.dart';
import 'package:cafe_pos/domain/repositories/settings_repository.dart';
import 'package:cafe_pos/domain/repositories/table_repository.dart';

class FixedIds implements IdGenerator {
  int _value = 0;

  @override
  String generate() {
    _value += 1;
    return '00000000-0000-4000-8000-${_value.toString().padLeft(12, '0')}';
  }
}

class FakeCategoryRepository implements CategoryRepository {
  final List<Category> values = <Category>[];

  @override
  Future<void> create(Category category) async => values.add(category);

  @override
  Future<Category?> findById(String id) async {
    return values.where((Category value) => value.id == id).firstOrNull;
  }

  @override
  Future<List<Category>> listAll() async =>
      List<Category>.of(values, growable: false);

  @override
  Future<int> nextSortOrder() async => values.length;

  @override
  Future<void> reorder(String id, int newIndex, DateTime updatedAt) async {
    final int oldIndex = values.indexWhere((Category value) => value.id == id);
    if (oldIndex < 0) {
      throw const EntityNotFoundError('La categoría ya no existe.');
    }
    final Category moved = values.removeAt(oldIndex);
    values.insert(
      newIndex.clamp(0, values.length),
      moved.copyWith(updatedAt: updatedAt),
    );
  }

  @override
  Future<void> update(Category category) async {
    final int index = values.indexWhere(
      (Category value) => value.id == category.id,
    );
    if (index < 0) {
      throw const EntityNotFoundError('La categoría ya no existe.');
    }
    values[index] = category;
  }
}

class FakeProductRepository implements ProductRepository {
  final List<Product> values = <Product>[];

  @override
  Future<void> create(Product product) async => values.add(product);

  @override
  Future<Product?> findById(String id) async {
    return values.where((Product value) => value.id == id).firstOrNull;
  }

  @override
  Future<List<Product>> listAll({String? categoryId}) async {
    return values
        .where(
          (Product value) =>
              categoryId == null || value.categoryId == categoryId,
        )
        .toList(growable: false);
  }

  @override
  Future<List<Product>> listSellable({String? categoryId}) async {
    return values
        .where(
          (Product value) =>
              productMatchesCategory(value, categoryId) &&
              value.isActive &&
              value.isAvailable,
        )
        .toList(growable: false);
  }

  bool productMatchesCategory(Product product, String? categoryId) {
    return categoryId == null || product.categoryId == categoryId;
  }

  @override
  Future<void> update(Product product) async {
    final int index = values.indexWhere(
      (Product value) => value.id == product.id,
    );
    if (index < 0) {
      throw const EntityNotFoundError('El producto ya no existe.');
    }
    values[index] = product;
  }
}

class FakeTableRepository implements TableRepository {
  final List<CafeTable> values = <CafeTable>[];
  Object? updateError;

  @override
  Future<void> create(CafeTable table) async => values.add(table);

  @override
  Future<CafeTable?> findById(String id) async {
    return values.where((CafeTable value) => value.id == id).firstOrNull;
  }

  @override
  Future<List<CafeTable>> listAll() async => List<CafeTable>.of(values);

  @override
  Future<int> nextSortOrder() async => values.length;

  @override
  Future<void> reorder(String id, int newIndex, DateTime updatedAt) async {
    final int oldIndex = values.indexWhere((CafeTable value) => value.id == id);
    if (oldIndex < 0) {
      throw const EntityNotFoundError('La mesa ya no existe.');
    }
    final CafeTable moved = values.removeAt(oldIndex);
    values.insert(
      newIndex.clamp(0, values.length),
      moved.copyWith(updatedAt: updatedAt),
    );
  }

  @override
  Future<void> update(CafeTable table) async {
    final Object? error = updateError;
    if (error != null) {
      throw error;
    }
    final int index = values.indexWhere(
      (CafeTable value) => value.id == table.id,
    );
    if (index < 0) {
      throw const EntityNotFoundError('La mesa ya no existe.');
    }
    values[index] = table;
  }
}

class FakeOrderRepository implements OrderRepository {
  final List<Order> orders = <Order>[];
  final List<OrderItem> items = <OrderItem>[];

  @override
  Future<void> create(Order order) async {
    if (orders.any(
      (Order value) =>
          order.tableId != null &&
          value.tableId == order.tableId &&
          value.status == OrderStatus.open,
    )) {
      throw const TableUnavailableError('La mesa ya tiene una orden abierta.');
    }
    orders.add(order);
  }

  @override
  Future<OrderDetails?> findDetails(String id) async {
    final Order? order = orders
        .where((Order value) => value.id == id)
        .firstOrNull;
    if (order == null) {
      return null;
    }
    return OrderDetails(
      order: order,
      items: items
          .where((OrderItem item) => item.orderId == id)
          .toList(growable: false),
    );
  }

  @override
  Future<void> insertItem(OrderItem item) async {
    _requireOpen(item.orderId);
    items.add(item);
  }

  @override
  Future<List<Order>> listOpen() async {
    return orders
        .where((Order order) => order.status == OrderStatus.open)
        .toList(growable: false);
  }

  @override
  Future<void> removeItem(String orderId, String itemId) async {
    _requireOpen(orderId);
    final int count = items.length;
    items.removeWhere(
      (OrderItem item) => item.orderId == orderId && item.id == itemId,
    );
    if (items.length == count) {
      throw const EntityNotFoundError('El producto ya no está en la orden.');
    }
  }

  @override
  Future<void> updateItem(OrderItem item) async {
    _requireOpen(item.orderId);
    final int index = items.indexWhere(
      (OrderItem value) => value.id == item.id && value.orderId == item.orderId,
    );
    if (index < 0) {
      throw const EntityNotFoundError('El producto ya no está en la orden.');
    }
    items[index] = item;
  }

  @override
  Future<void> updateTotal(
    String orderId,
    int totalCents,
    DateTime updatedAt,
  ) async {
    final int index = _requireOpen(orderId);
    orders[index] = orders[index].copyWith(
      totalCents: totalCents,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> cancel(
    String orderId,
    String reason,
    DateTime cancelledAt,
  ) async {
    final int index = _requireOpen(orderId);
    orders[index] = orders[index].copyWith(
      status: OrderStatus.cancelled,
      updatedAt: cancelledAt,
      cancelledAt: cancelledAt,
      cancellationReason: reason,
    );
  }

  @override
  Future<void> markPaid(String orderId, DateTime paidAt) async {
    final int index = _requireOpen(orderId);
    orders[index] = orders[index].copyWith(
      status: OrderStatus.paid,
      updatedAt: paidAt,
      paidAt: paidAt,
    );
  }

  int _requireOpen(String id) {
    final int index = orders.indexWhere((Order order) => order.id == id);
    if (index < 0) {
      throw const EntityNotFoundError('La orden ya no existe.');
    }
    if (orders[index].status != OrderStatus.open) {
      throw const OrderNotEditableError(
        'Solo se pueden modificar órdenes abiertas.',
      );
    }
    return index;
  }
}

class FakePaymentRepository implements PaymentRepository {
  final List<Payment> values = <Payment>[];
  Object? createError;

  @override
  Future<void> create(Payment payment) async {
    final Object? error = createError;
    if (error != null) {
      throw error;
    }
    if (values.any((Payment value) => value.orderId == payment.orderId)) {
      throw const DuplicatePaymentError('La orden ya fue pagada.');
    }
    values.add(payment);
  }

  @override
  Future<Payment?> findByOrderId(String orderId) async {
    return values
        .where((Payment value) => value.orderId == orderId)
        .firstOrNull;
  }
}

class FakeSalesRepository implements SalesRepository {
  final List<SaleSummary> values = <SaleSummary>[];
  final Map<String, SaleDetails> details = <String, SaleDetails>{};
  Object? error;

  @override
  Future<SaleDetails?> findDetails(String orderId) async {
    final Object? currentError = error;
    if (currentError != null) {
      throw currentError;
    }
    return details[orderId];
  }

  @override
  Future<List<SaleSummary>> list({
    int? orderNumber,
    UtcDateRange? paidRange,
    PaymentMethod? paymentMethod,
  }) async {
    final Object? currentError = error;
    if (currentError != null) {
      throw currentError;
    }
    return values
        .where(
          (SaleSummary sale) =>
              (orderNumber == null || sale.orderNumber == orderNumber) &&
              (paidRange == null ||
                  (!sale.paidAt.isBefore(paidRange.start) &&
                      sale.paidAt.isBefore(paidRange.end))) &&
              (paymentMethod == null || sale.paymentMethod == paymentMethod),
        )
        .toList(growable: false);
  }
}

class FakeReportRepository implements ReportRepository {
  SalesReport value = const SalesReport(
    netSalesCents: 0,
    paidOrderCount: 0,
    unitsSold: 0,
    bestSellingProducts: <ProductUnits>[],
    salesByCategory: <NamedSalesTotal>[],
    salesByHour: <HourlySalesTotal>[],
    totalsByPaymentMethod: <PaymentMethodTotal>[],
  );
  Object? error;

  @override
  Future<SalesReport> load(UtcDateRange paidRange) async {
    final Object? currentError = error;
    if (currentError != null) {
      throw currentError;
    }
    return value;
  }
}

class FakeSettingsRepository implements SettingsRepository {
  int lastOrderNumber = 0;

  @override
  Future<int> allocateNextOrderNumber(DateTime updatedAt) async {
    lastOrderNumber += 1;
    return lastOrderNumber;
  }

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      businessName: 'Cafetería',
      timezone: 'America/El_Salvador',
      lastOrderNumber: lastOrderNumber,
    );
  }

  @override
  Future<void> setValue(String key, String value, DateTime updatedAt) async {
    if (key == 'last_order_number') {
      lastOrderNumber = int.parse(value);
    }
  }
}

class DirectTransactionRunner implements TransactionRunner {
  const DirectTransactionRunner(this.repositories);

  final TransactionRepositories repositories;

  @override
  Future<T> run<T>(
    Future<T> Function(TransactionRepositories repositories) operation,
  ) {
    return operation(repositories);
  }
}
