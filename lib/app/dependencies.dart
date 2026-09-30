import '../application/services/id_generator.dart';
import '../application/use_cases/catalog_use_cases.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/repositories/sqlite_category_repository.dart';
import '../infrastructure/repositories/sqlite_product_repository.dart';

Future<CatalogUseCases> buildCatalogUseCases() async {
  final AppDatabase database = AppDatabase();
  await database.initialize();
  return CatalogUseCases(
    categories: SqliteCategoryRepository(database),
    products: SqliteProductRepository(database),
    ids: const UuidIdGenerator(),
    clock: DateTime.now,
  );
}
