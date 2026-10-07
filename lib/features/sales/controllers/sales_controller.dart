import 'package:flutter/foundation.dart';

import '../../../application/use_cases/sales_use_cases.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/errors/domain_error.dart';

enum SalesStatus { loading, ready, error }

enum SaleDetailsStatus { idle, loading, ready, error }

class SalesController extends ChangeNotifier {
  SalesController(this._sales);

  final SalesUseCases _sales;

  SalesStatus status = SalesStatus.loading;
  SaleDetailsStatus detailsStatus = SaleDetailsStatus.idle;
  List<SaleSummary> sales = <SaleSummary>[];
  SaleDetails? selected;
  String? errorMessage;
  String? orderNumberError;
  String? detailsErrorMessage;
  String orderNumber = '';
  DateTime? startDate;
  DateTime? endDate;
  PaymentMethod? paymentMethod;

  Future<void> load() async {
    status = SalesStatus.loading;
    errorMessage = null;
    orderNumberError = null;
    notifyListeners();
    try {
      sales = await _sales.search(
        orderNumber: orderNumber,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
      );
      if (selected != null &&
          !sales.any(
            (SaleSummary sale) => sale.orderId == selected!.sale.orderId,
          )) {
        selected = null;
        detailsStatus = SaleDetailsStatus.idle;
      }
      status = SalesStatus.ready;
    } on ValidationError catch (error) {
      if (error.field == 'orderNumber') {
        status = SalesStatus.ready;
        orderNumberError = error.message;
      } else {
        status = SalesStatus.error;
        errorMessage = error.message;
      }
    } on Object catch (error) {
      status = SalesStatus.error;
      errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  Future<void> applyFilters({
    required String orderNumber,
    required DateTime? startDate,
    required DateTime? endDate,
    required PaymentMethod? paymentMethod,
  }) async {
    this.orderNumber = orderNumber;
    this.startDate = startDate;
    this.endDate = endDate;
    this.paymentMethod = paymentMethod;
    await load();
  }

  Future<void> clearFilters() {
    return applyFilters(
      orderNumber: '',
      startDate: null,
      endDate: null,
      paymentMethod: null,
    );
  }

  Future<void> selectSale(String orderId) async {
    detailsStatus = SaleDetailsStatus.loading;
    detailsErrorMessage = null;
    notifyListeners();
    try {
      selected = await _sales.loadDetails(orderId);
      detailsStatus = SaleDetailsStatus.ready;
    } on Object catch (error) {
      detailsStatus = SaleDetailsStatus.error;
      detailsErrorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  String _messageFor(Object error) {
    if (error is DomainError) {
      return error.message;
    }
    return 'No se pudo cargar el historial. Intenta nuevamente.';
  }
}
