import 'package:cafe_pos/application/services/id_generator.dart';
import 'package:cafe_pos/application/use_cases/catalog_use_cases.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/product.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/domain/repositories/category_repository.dart';
import 'package:cafe_pos/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _CategoryFake categories;
  late _ProductFake products;
  late CatalogUseCases useCases;
  final DateTime now = DateTime.utc(2026, 9, 29, 18, 30);

  setUp(() {
    categories = _CategoryFake();
    products = _ProductFake();
    useCases = CatalogUseCases(
      categories: categories,
      products: products,
      ids: _FixedIds(),
      clock: () => now,
    );
  });

  test(
    'creates trimmed categories with an application UUID and UTC time',
    () async {
      final Category result = await useCases.createCategory('  Bebidas ');

      expect(result.id, '00000000-0000-4000-8000-000000000001');
      expect(result.name, 'Bebidas');
      expect(result.sortOrder, 0);
      expect(result.createdAt, now);
      expect(categories.values, contains(result));
    },
  );

  test('rejects an empty category name', () async {
    await expectLater(
      useCases.createCategory('   '),
      throwsA(isA<ValidationError>()),
    );
  });

  test('creates a product with exact cents', () async {
    final Category category = await useCases.createCategory('Comida');

    final Product product = await useCases.createProduct(
      categoryId: category.id,
      name: ' Croissant ',
      price: '2.50',
    );

    expect(product.name, 'Croissant');
    expect(product.priceCents, 250);
    expect(product.isActive, isTrue);
    expect(product.isAvailable, isTrue);
  });

  test('requires an existing category for products', () async {
    await expectLater(
      useCases.createProduct(
        categoryId: 'missing',
        name: 'Café',
        price: '1.00',
      ),
      throwsA(isA<EntityNotFoundError>()),
    );
  });
}

class _FixedIds implements IdGenerator {
  int _value = 0;

  @override
  String generate() {
    _value += 1;
    return '00000000-0000-4000-8000-${_value.toString().padLeft(12, '0')}';
  }
}

class _CategoryFake implements CategoryRepository {
  final List<Category> values = <Category>[];

  @override
  Future<void> create(Category category) async => values.add(category);

  @override
  Future<Category?> findById(String id) async {
    return values.where((Category value) => value.id == id).firstOrNull;
  }

  @override
  Future<List<Category>> listAll() async => List<Category>.of(values);

  @override
  Future<int> nextSortOrder() async => values.length;

  @override
  Future<void> reorder(String id, int newIndex, DateTime updatedAt) async {
    final int oldIndex = values.indexWhere((Category value) => value.id == id);
    final Category moved = values.removeAt(oldIndex);
    values.insert(newIndex, moved.copyWith(updatedAt: updatedAt));
  }

  @override
  Future<void> update(Category category) async {
    final int index = values.indexWhere(
      (Category value) => value.id == category.id,
    );
    values[index] = category;
  }
}

class _ProductFake implements ProductRepository {
  final List<Product> values = <Product>[];

  @override
  Future<void> create(Product product) async => values.add(product);

  @override
  Future<Product?> findById(String id) async {
    return values.where((Product value) => value.id == id).firstOrNull;
  }

  @override
  Future<List<Product>> listAll({String? categoryId}) async {
    return values
        .where(
          (Product value) =>
              categoryId == null || value.categoryId == categoryId,
        )
        .toList();
  }

  @override
  Future<List<Product>> listSellable({String? categoryId}) {
    return listAll(categoryId: categoryId);
  }

  @override
  Future<void> update(Product product) async {
    final int index = values.indexWhere(
      (Product value) => value.id == product.id,
    );
    values[index] = product;
  }
}
