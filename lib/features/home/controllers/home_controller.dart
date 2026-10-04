import 'package:flutter/foundation.dart';

import '../../../application/use_cases/order_use_cases.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/errors/domain_error.dart';

enum HomeStatus { loading, ready, error }

class HomeController extends ChangeNotifier {
  HomeController(this._orders);

  final OrderUseCases _orders;

  HomeStatus status = HomeStatus.loading;
  HomeData? data;
  String? errorMessage;
  bool isSaving = false;

  Future<void> load() async {
    status = HomeStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _orders.loadHome();
      status = HomeStatus.ready;
    } on Object catch (error) {
      status = HomeStatus.error;
      errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  Future<Order?> createDineIn(String tableId) {
    return _create(() => _orders.createDineIn(tableId));
  }

  Future<Order?> createTakeaway() {
    return _create(_orders.createTakeaway);
  }

  Future<Order?> _create(Future<Order> Function() operation) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final Order order = await operation();
      data = await _orders.loadHome();
      return order;
    } on Object catch (error) {
      errorMessage = _messageFor(error);
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is DomainError) {
      return error.message;
    }
    return 'No se pudieron cargar las órdenes. Intenta nuevamente.';
  }
}
