import 'package:sqflite/sqflite.dart';

import '../../application/services/transaction_runner.dart';
import '../repositories/sqlite_category_repository.dart';
import '../repositories/sqlite_order_repository.dart';
import '../repositories/sqlite_product_repository.dart';
import '../repositories/sqlite_settings_repository.dart';
import '../repositories/sqlite_table_repository.dart';
import 'app_database.dart';

class SqliteTransactionRunner implements TransactionRunner {
  const SqliteTransactionRunner(this._provider);

  final AppDatabase _provider;

  @override
  Future<T> run<T>(
    Future<T> Function(TransactionRepositories repositories) operation,
  ) async {
    final Database database = await _provider.database;
    return database.transaction<T>((Transaction transaction) {
      return operation(
        TransactionRepositories(
          categories: SqliteCategoryRepository.executor(transaction),
          products: SqliteProductRepository.executor(transaction),
          tables: SqliteTableRepository.executor(transaction),
          orders: SqliteOrderRepository.executor(transaction),
          settings: SqliteSettingsRepository.executor(transaction),
        ),
      );
    });
  }
}
