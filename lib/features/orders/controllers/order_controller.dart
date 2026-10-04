import 'package:flutter/foundation.dart' hide Category;

import '../../../application/use_cases/order_use_cases.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/order_details.dart';
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/errors/domain_error.dart';

enum OrderEditorStatus { loading, ready, error }

class OrderController extends ChangeNotifier {
  OrderController(this._orders, this.orderId);

  final OrderUseCases _orders;
  final String orderId;

  OrderEditorStatus status = OrderEditorStatus.loading;
  OrderDetails? details;
  List<Category> categories = <Category>[];
  List<Product> products = <Product>[];
  String? selectedCategoryId;
  String? errorMessage;
  bool isSaving = false;

  List<Product> get selectedProducts => products
      .where((Product product) => product.categoryId == selectedCategoryId)
      .toList(growable: false);

  bool canIncrease(OrderItem item) {
    return products.any((Product product) => product.id == item.productId);
  }

  Future<void> load() async {
    status = OrderEditorStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      details = await _orders.loadOrder(orderId);
      final OrderCatalog catalog = await _orders.loadCatalog();
      categories = catalog.categories;
      products = catalog.products;
      if (!categories.any(
        (Category category) => category.id == selectedCategoryId,
      )) {
        selectedCategoryId = categories.firstOrNull?.id;
      }
      status = OrderEditorStatus.ready;
    } on Object catch (error) {
      status = OrderEditorStatus.error;
      errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  void selectCategory(String id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  Future<bool> addProduct(String productId) {
    return _write(() => _orders.addProduct(orderId, productId));
  }

  Future<bool> setQuantity(OrderItem item, int quantity) {
    return _write(() => _orders.setQuantity(orderId, item.id, quantity));
  }

  Future<bool> saveNote(OrderItem item, String note) {
    return _write(() => _orders.saveNote(orderId, item.id, note));
  }

  Future<bool> cancel(String reason) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _orders.cancelOrder(orderId, reason);
      return true;
    } on Object catch (error) {
      errorMessage = _messageFor(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _write(Future<OrderDetails> Function() operation) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      details = await operation();
      final OrderCatalog catalog = await _orders.loadCatalog();
      categories = catalog.categories;
      products = catalog.products;
      return true;
    } on Object catch (error) {
      errorMessage = _messageFor(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is DomainError) {
      return error.message;
    }
    return 'No se pudo guardar la orden. Intenta nuevamente.';
  }
}
