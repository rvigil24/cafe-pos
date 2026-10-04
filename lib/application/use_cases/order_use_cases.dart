import '../../domain/entities/cafe_table.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_details.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/table_repository.dart';
import '../services/id_generator.dart';
import '../services/transaction_runner.dart';

typedef OrderClock = DateTime Function();

class HomeData {
  const HomeData({required this.tables, required this.openOrders});

  final List<CafeTable> tables;
  final List<Order> openOrders;

  Order? orderForTable(String tableId) {
    for (final Order order in openOrders) {
      if (order.tableId == tableId) {
        return order;
      }
    }
    return null;
  }

  List<Order> get takeawayOrders => openOrders
      .where((Order order) => order.type == OrderType.takeaway)
      .toList(growable: false);
}

class OrderCatalog {
  const OrderCatalog({required this.categories, required this.products});

  final List<Category> categories;
  final List<Product> products;
}

class OrderUseCases {
  const OrderUseCases({
    required TableRepository tables,
    required OrderRepository orders,
    required CategoryRepository categories,
    required ProductRepository products,
    required TransactionRunner transactions,
    required IdGenerator ids,
    required OrderClock clock,
  }) : this._internal(
         tables,
         orders,
         categories,
         products,
         transactions,
         ids,
         clock,
       );

  const OrderUseCases._internal(
    this._tables,
    this._orders,
    this._categories,
    this._products,
    this._transactions,
    this._ids,
    this._clock,
  );

  final TableRepository _tables;
  final OrderRepository _orders;
  final CategoryRepository _categories;
  final ProductRepository _products;
  final TransactionRunner _transactions;
  final IdGenerator _ids;
  final OrderClock _clock;

  Future<HomeData> loadHome() async {
    final List<CafeTable> tables = await _tables.listAll();
    final List<Order> orders = await _orders.listOpen();
    return HomeData(
      tables: tables
          .where((CafeTable table) => table.isActive)
          .toList(growable: false),
      openOrders: orders,
    );
  }

  Future<OrderCatalog> loadCatalog() async {
    final List<Category> categories = await _categories.listAll();
    final List<Product> products = await _products.listSellable();
    return OrderCatalog(
      categories: categories
          .where((Category category) => category.isActive)
          .toList(growable: false),
      products: products,
    );
  }

  Future<OrderDetails> loadOrder(String orderId) async {
    final OrderDetails? details = await _orders.findDetails(orderId);
    if (details == null) {
      throw const EntityNotFoundError('La orden ya no existe.');
    }
    return details;
  }

  Future<Order> createDineIn(String tableId) {
    return _transactions.run<Order>((TransactionRepositories tx) async {
      final CafeTable? table = await tx.tables.findById(tableId);
      if (table == null || !table.isActive) {
        throw const TableUnavailableError(
          'La mesa no está disponible para una nueva orden.',
        );
      }
      final List<Order> openOrders = await tx.orders.listOpen();
      if (openOrders.any((Order order) => order.tableId == tableId)) {
        throw const TableUnavailableError(
          'La mesa ya tiene una orden abierta.',
        );
      }
      return _createOrder(tx, table: table);
    });
  }

  Future<Order> createTakeaway() {
    return _transactions.run<Order>(
      (TransactionRepositories tx) => _createOrder(tx),
    );
  }

  Future<OrderDetails> addProduct(String orderId, String productId) {
    return _transactions.run<OrderDetails>((TransactionRepositories tx) async {
      final OrderDetails details = await _requireOpen(tx.orders, orderId);
      final Product product = await _requireSellableProduct(tx, productId);
      final OrderItem? existing = _itemForProduct(details.items, productId);
      final DateTime now = _utcNow();
      if (existing == null) {
        final Category? category = await tx.categories.findById(
          product.categoryId,
        );
        if (category == null || !category.isActive) {
          throw const ProductUnavailableError(
            'El producto ya no está disponible.',
          );
        }
        await tx.orders.insertItem(
          OrderItem(
            id: _ids.generate(),
            orderId: orderId,
            productId: product.id,
            productNameSnapshot: product.name,
            categoryNameSnapshot: category.name,
            quantity: 1,
            unitPriceCents: product.priceCents,
            note: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await tx.orders.updateItem(
          existing.copyWith(quantity: existing.quantity + 1, updatedAt: now),
        );
      }
      final int total =
          details.order.totalCents +
          (existing?.unitPriceCents ?? product.priceCents);
      await tx.orders.updateTotal(orderId, total, now);
      return (await tx.orders.findDetails(orderId))!;
    });
  }

  Future<OrderDetails> setQuantity(
    String orderId,
    String itemId,
    int quantity,
  ) {
    return _transactions.run<OrderDetails>((TransactionRepositories tx) async {
      final OrderDetails details = await _requireOpen(tx.orders, orderId);
      final OrderItem item = _requireItem(details.items, itemId);
      if (quantity > item.quantity) {
        final String? productId = item.productId;
        if (productId == null) {
          throw const ProductUnavailableError(
            'El producto ya no está disponible.',
          );
        }
        await _requireSellableProduct(tx, productId);
      }
      final DateTime now = _utcNow();
      if (quantity <= 0) {
        await tx.orders.removeItem(orderId, itemId);
      } else {
        await tx.orders.updateItem(
          item.copyWith(quantity: quantity, updatedAt: now),
        );
      }
      final int total =
          details.order.totalCents +
          ((quantity <= 0 ? 0 : quantity) - item.quantity) *
              item.unitPriceCents;
      await tx.orders.updateTotal(orderId, total, now);
      return (await tx.orders.findDetails(orderId))!;
    });
  }

  Future<OrderDetails> saveNote(String orderId, String itemId, String rawNote) {
    return _transactions.run<OrderDetails>((TransactionRepositories tx) async {
      final OrderDetails details = await _requireOpen(tx.orders, orderId);
      final OrderItem item = _requireItem(details.items, itemId);
      final String note = rawNote.trim();
      await tx.orders.updateItem(
        item.copyWith(
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
          updatedAt: _utcNow(),
        ),
      );
      return (await tx.orders.findDetails(orderId))!;
    });
  }

  Future<void> cancelOrder(String orderId, String rawReason) async {
    final String reason = rawReason.trim();
    if (reason.isEmpty) {
      throw const ValidationError(
        'Ingresa el motivo de cancelación.',
        field: 'reason',
      );
    }
    await _transactions.run<void>((TransactionRepositories tx) async {
      await _requireOpen(tx.orders, orderId);
      await tx.orders.cancel(orderId, reason, _utcNow());
    });
  }

  Future<Order> _createOrder(
    TransactionRepositories tx, {
    CafeTable? table,
  }) async {
    final DateTime now = _utcNow();
    final int orderNumber = await tx.settings.allocateNextOrderNumber(now);
    final Order order = Order(
      id: _ids.generate(),
      orderNumber: orderNumber,
      tableId: table?.id,
      tableNameSnapshot: table?.name,
      type: table == null ? OrderType.takeaway : OrderType.dineIn,
      status: OrderStatus.open,
      totalCents: 0,
      createdAt: now,
      updatedAt: now,
      paidAt: null,
      cancelledAt: null,
      cancellationReason: null,
    );
    await tx.orders.create(order);
    return order;
  }

  Future<OrderDetails> _requireOpen(
    OrderRepository orders,
    String orderId,
  ) async {
    final OrderDetails? details = await orders.findDetails(orderId);
    if (details == null) {
      throw const EntityNotFoundError('La orden ya no existe.');
    }
    if (details.order.status != OrderStatus.open) {
      throw const OrderNotEditableError(
        'Solo se pueden modificar órdenes abiertas.',
      );
    }
    return details;
  }

  Future<Product> _requireSellableProduct(
    TransactionRepositories tx,
    String productId,
  ) async {
    final Product? product = await tx.products.findById(productId);
    if (product == null || !product.isActive || !product.isAvailable) {
      throw const ProductUnavailableError('El producto ya no está disponible.');
    }
    final Category? category = await tx.categories.findById(product.categoryId);
    if (category == null || !category.isActive) {
      throw const ProductUnavailableError('El producto ya no está disponible.');
    }
    return product;
  }

  OrderItem? _itemForProduct(List<OrderItem> items, String productId) {
    for (final OrderItem item in items) {
      if (item.productId == productId) {
        return item;
      }
    }
    return null;
  }

  OrderItem _requireItem(List<OrderItem> items, String itemId) {
    for (final OrderItem item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    throw const EntityNotFoundError('El producto ya no está en la orden.');
  }

  DateTime _utcNow() => _clock().toUtc();
}
