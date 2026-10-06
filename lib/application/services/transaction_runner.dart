import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/table_repository.dart';

class TransactionRepositories {
  const TransactionRepositories({
    required this.categories,
    required this.products,
    required this.tables,
    required this.orders,
    required this.payments,
    required this.settings,
  });

  final CategoryRepository categories;
  final ProductRepository products;
  final TableRepository tables;
  final OrderRepository orders;
  final PaymentRepository payments;
  final SettingsRepository settings;
}

abstract interface class TransactionRunner {
  Future<T> run<T>(
    Future<T> Function(TransactionRepositories repositories) operation,
  );
}
