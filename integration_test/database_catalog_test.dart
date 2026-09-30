import 'dart:io';

import 'package:cafe_pos/application/services/id_generator.dart';
import 'package:cafe_pos/application/use_cases/catalog_use_cases.dart';
import 'package:cafe_pos/domain/entities/cafe_table.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/product.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/infrastructure/database/app_database.dart';
import 'package:cafe_pos/infrastructure/database/migrations/migration.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_category_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_product_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_settings_repository.dart';
import 'package:cafe_pos/infrastructure/repositories/sqlite_table_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String databasePath;

  setUp(() async {
    final Directory directory = await getTemporaryDirectory();
    databasePath = path.join(directory.path, 'catalog_repository_test.db');
    await deleteDatabase(databasePath);
  });

  tearDown(() => deleteDatabase(databasePath));

  testWidgets('migrates a fresh database once and preserves catalog data', (
    WidgetTester tester,
  ) async {
    final AppDatabase provider = AppDatabase(databasePath: databasePath);
    final Database database = await provider.initialize();

    expect(await _userVersion(database), 1);
    expect(
      Sqflite.firstIntValue(await database.rawQuery('PRAGMA foreign_keys')),
      1,
    );
    final List<String> tables = (await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((Map<String, Object?> row) => row['name']! as String).toList();
    expect(
      tables,
      containsAll(<String>[
        'categories',
        'products',
        'cafe_tables',
        'orders',
        'order_items',
        'payments',
        'settings',
      ]),
    );

    final SqliteCategoryRepository categories = SqliteCategoryRepository(
      provider,
    );
    final SqliteProductRepository products = SqliteProductRepository(provider);
    final CatalogUseCases catalog = CatalogUseCases(
      categories: categories,
      products: products,
      ids: const UuidIdGenerator(),
      clock: () => DateTime.utc(2026, 9, 29, 21, 5),
    );
    final Category cold = await catalog.createCategory('Frías');
    final Category hot = await catalog.createCategory('Calientes');
    await catalog.createProduct(categoryId: hot.id, name: 'Té', price: '1.25');
    final Product coffee = await catalog.createProduct(
      categoryId: hot.id,
      name: 'Café',
      price: '2.50',
    );

    expect(
      (await products.listAll(categoryId: hot.id)).map((p) => p.name),
      <String>['Café', 'Té'],
    );
    expect(coffee.priceCents, 250);

    await catalog.setProductAvailable(coffee, false);
    expect((await products.findById(coffee.id))!.isAvailable, isFalse);
    expect(
      (await products.listSellable(categoryId: hot.id)).map((p) => p.name),
      <String>['Té'],
    );
    await catalog.setProductAvailable(
      (await products.findById(coffee.id))!,
      true,
    );
    await catalog.editProduct(
      product: (await products.findById(coffee.id))!,
      categoryId: hot.id,
      name: 'Espresso',
      price: '2.75',
    );
    expect((await products.findById(coffee.id))!.priceCents, 275);
    await catalog.setProductActive(
      (await products.findById(coffee.id))!,
      false,
    );
    expect(await products.listSellable(categoryId: hot.id), hasLength(1));
    await catalog.setProductActive((await products.findById(coffee.id))!, true);

    await catalog.setCategoryActive(hot, false);
    expect(await products.listSellable(categoryId: hot.id), isEmpty);
    expect((await products.findById(coffee.id))!.isActive, isTrue);
    await catalog.setCategoryActive((await categories.findById(hot.id))!, true);
    expect(await products.listSellable(categoryId: hot.id), hasLength(2));

    await catalog.reorderCategory(cold.id, 0);
    expect((await categories.listAll()).first.id, cold.id);

    await expectLater(
      catalog.createCategory('frías'),
      throwsA(isA<DuplicateActiveNameError>()),
    );

    final SqliteSettingsRepository settings = SqliteSettingsRepository(
      provider,
    );
    expect((await settings.load()).timezone, 'America/El_Salvador');
    expect((await settings.load()).businessName, 'Cafetería');
    await settings.setValue(
      'business_name',
      'Café de prueba',
      DateTime.utc(2026, 9, 29, 21, 6),
    );
    expect((await settings.load()).businessName, 'Café de prueba');

    final DateTime now = DateTime.utc(2026, 9, 29, 21, 5);
    final SqliteTableRepository tablesRepository = SqliteTableRepository(
      provider,
    );
    final CafeTable table = CafeTable(
      id: const UuidIdGenerator().generate(),
      name: 'Mesa 1',
      sortOrder: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await tablesRepository.create(table);
    expect(await tablesRepository.listAll(), hasLength(1));
    final CafeTable renamedTable = CafeTable(
      id: table.id,
      name: 'Terraza',
      sortOrder: 2,
      isActive: true,
      createdAt: table.createdAt,
      updatedAt: now,
    );
    await tablesRepository.update(renamedTable);
    expect((await tablesRepository.findById(table.id))!.name, 'Terraza');
    await database.insert('orders', <String, Object?>{
      'id': const UuidIdGenerator().generate(),
      'order_number': 1,
      'table_id': table.id,
      'table_name_snapshot': renamedTable.name,
      'type': 'DINE_IN',
      'status': 'OPEN',
      'total_cents': 0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await expectLater(
      tablesRepository.update(
        CafeTable(
          id: table.id,
          name: renamedTable.name,
          sortOrder: renamedTable.sortOrder,
          isActive: false,
          createdAt: table.createdAt,
          updatedAt: now,
        ),
      ),
      throwsA(isA<OccupiedTableError>()),
    );

    final String createdAt =
        (await database.query(
              'products',
              columns: <String>['created_at'],
              where: 'id = ?',
              whereArgs: <Object?>[coffee.id],
            )).single['created_at']!
            as String;
    expect(createdAt, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T.*Z$')));

    await provider.close();
    final AppDatabase reopened = AppDatabase(databasePath: databasePath);
    final SqliteProductRepository reopenedProducts = SqliteProductRepository(
      reopened,
    );
    expect(await reopenedProducts.listAll(), hasLength(2));
    expect(await _userVersion(await reopened.database), 1);
    await reopened.close();
  });

  testWidgets('rolls back schema and user_version when a migration fails', (
    WidgetTester tester,
  ) async {
    final AppDatabase versionOne = AppDatabase(
      databasePath: databasePath,
      migrationLoader: () async => const <Migration>[
        Migration(
          version: 1,
          sql:
              'CREATE TABLE stable (id INTEGER PRIMARY KEY);'
              'INSERT INTO stable(id) VALUES (1);',
        ),
      ],
    );
    await versionOne.initialize();
    await versionOne.close();

    final AppDatabase failing = AppDatabase(
      databasePath: databasePath,
      migrationLoader: () async => const <Migration>[
        Migration(
          version: 1,
          sql: 'CREATE TABLE stable (id INTEGER PRIMARY KEY);',
        ),
        Migration(
          version: 2,
          sql: 'CREATE TABLE must_roll_back (id INTEGER); THIS IS NOT SQL;',
        ),
      ],
    );
    await expectLater(failing.initialize(), throwsA(isA<PersistenceError>()));

    final Database inspected = await openDatabase(
      databasePath,
      singleInstance: false,
    );
    try {
      expect(await _userVersion(inspected), 1);
      expect(
        await inspected.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          <Object?>['must_roll_back'],
        ),
        isEmpty,
      );
      expect(
        Sqflite.firstIntValue(
          await inspected.rawQuery('SELECT COUNT(*) FROM stable'),
        ),
        1,
      );
    } finally {
      await inspected.close();
    }
  });
}

Future<int> _userVersion(Database database) async {
  return Sqflite.firstIntValue(await database.rawQuery('PRAGMA user_version'))!;
}
