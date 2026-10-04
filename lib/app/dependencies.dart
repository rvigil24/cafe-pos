import 'package:timezone/data/latest.dart' as tz;

import '../application/services/id_generator.dart';
import '../application/use_cases/catalog_use_cases.dart';
import '../application/use_cases/order_use_cases.dart';
import '../application/use_cases/table_use_cases.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/database/sqlite_transaction_runner.dart';
import '../infrastructure/repositories/sqlite_category_repository.dart';
import '../infrastructure/repositories/sqlite_order_repository.dart';
import '../infrastructure/repositories/sqlite_product_repository.dart';
import '../infrastructure/repositories/sqlite_table_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.catalog,
    required this.tables,
    required this.orders,
  });

  final CatalogUseCases catalog;
  final TableUseCases tables;
  final OrderUseCases orders;
}

Future<AppDependencies> buildAppDependencies() async {
  tz.initializeTimeZones();
  final AppDatabase database = AppDatabase();
  await database.initialize();
  final SqliteCategoryRepository categories = SqliteCategoryRepository(
    database,
  );
  final SqliteProductRepository products = SqliteProductRepository(database);
  final SqliteTableRepository tables = SqliteTableRepository(database);
  final SqliteOrderRepository orders = SqliteOrderRepository(database);
  const UuidIdGenerator ids = UuidIdGenerator();
  return AppDependencies(
    catalog: CatalogUseCases(
      categories: categories,
      products: products,
      ids: ids,
      clock: DateTime.now,
    ),
    tables: TableUseCases(tables: tables, ids: ids, clock: DateTime.now),
    orders: OrderUseCases(
      tables: tables,
      orders: orders,
      categories: categories,
      products: products,
      transactions: SqliteTransactionRunner(database),
      ids: ids,
      clock: DateTime.now,
    ),
  );
}
