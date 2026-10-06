import 'package:cafe_pos/application/use_cases/catalog_use_cases.dart';
import 'package:cafe_pos/application/use_cases/table_use_cases.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/product.dart';

class SeedProduct {
  const SeedProduct(this.name, this.price);

  final String name;
  final String price;
}

class SeedCategory {
  const SeedCategory(this.name, this.products);

  final String name;
  final List<SeedProduct> products;
}

class SeedSummary {
  const SeedSummary({
    required this.tablesCreated,
    required this.categoriesCreated,
    required this.productsCreated,
  });

  final int tablesCreated;
  final int categoriesCreated;
  final int productsCreated;

  int get totalCreated => tablesCreated + categoriesCreated + productsCreated;

  @override
  String toString() {
    return '$tablesCreated mesas, $categoriesCreated categorías y '
        '$productsCreated productos creados';
  }
}

class DevelopmentSeeder {
  const DevelopmentSeeder({required this.catalog, required this.tables});

  final CatalogUseCases catalog;
  final TableUseCases tables;

  static const List<String> tableNames = <String>[
    'Mesa 1',
    'Mesa 2',
    'Mesa 3',
    'Mesa 4',
    'Mesa 5',
    'Mesa 6',
    'Barra 1',
    'Terraza 1',
  ];

  static const List<SeedCategory> categories = <SeedCategory>[
    SeedCategory('Café', <SeedProduct>[
      SeedProduct('Espresso', '1.50'),
      SeedProduct('Americano', '2.00'),
      SeedProduct('Cappuccino', '2.75'),
      SeedProduct('Latte', '3.00'),
    ]),
    SeedCategory('Bebidas frías', <SeedProduct>[
      SeedProduct('Agua', '1.00'),
      SeedProduct('Limonada', '2.50'),
      SeedProduct('Té frío', '2.25'),
    ]),
    SeedCategory('Panadería', <SeedProduct>[
      SeedProduct('Croissant', '2.25'),
      SeedProduct('Pan dulce', '1.50'),
      SeedProduct('Sándwich', '4.50'),
    ]),
    SeedCategory('Postres', <SeedProduct>[
      SeedProduct('Brownie', '2.50'),
      SeedProduct('Cheesecake', '3.50'),
    ]),
  ];

  Future<SeedSummary> seed() async {
    int tablesCreated = 0;
    int categoriesCreated = 0;
    int productsCreated = 0;

    final Set<String> existingTableNames = (await tables.listTables())
        .map((table) => _key(table.name))
        .toSet();
    for (final String name in tableNames) {
      if (existingTableNames.add(_key(name))) {
        await tables.createTable(name);
        tablesCreated += 1;
      }
    }

    final List<Category> existingCategories = List<Category>.of(
      await catalog.listCategories(),
    );
    for (final SeedCategory seedCategory in categories) {
      Category? category = existingCategories
          .where(
            (Category value) => _key(value.name) == _key(seedCategory.name),
          )
          .firstOrNull;
      if (category == null) {
        category = await catalog.createCategory(seedCategory.name);
        existingCategories.add(category);
        categoriesCreated += 1;
      }

      final Set<String> existingProductNames = (await catalog.listProducts(
        categoryId: category.id,
      )).map((Product product) => _key(product.name)).toSet();
      for (final SeedProduct product in seedCategory.products) {
        if (existingProductNames.add(_key(product.name))) {
          await catalog.createProduct(
            categoryId: category.id,
            name: product.name,
            price: product.price,
          );
          productsCreated += 1;
        }
      }
    }

    return SeedSummary(
      tablesCreated: tablesCreated,
      categoriesCreated: categoriesCreated,
      productsCreated: productsCreated,
    );
  }

  String _key(String value) => value.trim().toLowerCase();
}
