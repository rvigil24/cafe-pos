import 'dart:async';

import 'package:cafe_pos/application/services/id_generator.dart';
import 'package:cafe_pos/application/use_cases/catalog_use_cases.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/product.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/domain/repositories/category_repository.dart';
import 'package:cafe_pos/domain/repositories/product_repository.dart';
import 'package:cafe_pos/features/products/controllers/catalog_controller.dart';
import 'package:cafe_pos/features/products/pages/catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates a category and validates product price input', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final _CategoryFake categories = _CategoryFake();
    final CatalogController controller = _controller(categories);

    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay categorías'), findsOneWidget);

    await tester.tap(find.byTooltip('Crear categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Bebidas');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Categoría creada.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Nuevo producto'));
    await tester.pumpAndSettle();
    final Finder fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Café');
    await tester.enterText(fields.at(1), '1.234');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    expect(
      find.text('Usa un número no negativo con máximo dos decimales.'),
      findsOneWidget,
    );

    await tester.enterText(fields.at(1), '1.25');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Café'), findsOneWidget);
    expect(find.textContaining('1.25'), findsOneWidget);
  });

  testWidgets('asks for confirmation before deactivating a category', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final _CategoryFake categories = _CategoryFake()
      ..values.add(_category('one', 'Bebidas'));

    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(controller: _controller(categories))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Acciones de Bebidas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar desactivación'), findsOneWidget);
    expect(find.textContaining('El historial no cambiará.'), findsOneWidget);
  });

  testWidgets('category form stays usable with a landscape keyboard viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final CatalogController controller = _controller(_CategoryFake());
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Crear categoría'));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextFormField));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Guardar'), findsOneWidget);
  });

  testWidgets('shows a recoverable loading error', (WidgetTester tester) async {
    final _CategoryFake categories = _CategoryFake()..failLists = true;
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(controller: _controller(categories))),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo leer el catálogo.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
  });

  test(
    'controller exposes an in-progress state while a write is pending',
    () async {
      final _CategoryFake categories = _CategoryFake();
      final Completer<void> pending = Completer<void>();
      categories.createBarrier = pending;
      final CatalogController controller = _controller(categories);
      await controller.load();

      final Future<bool> result = controller.createCategory('Bebidas');
      expect(controller.isSaving, isTrue);
      pending.complete();
      expect(await result, isTrue);
      expect(controller.isSaving, isFalse);
    },
  );
}

CatalogController _controller(_CategoryFake categories) {
  return CatalogController(
    CatalogUseCases(
      categories: categories,
      products: _ProductFake(),
      ids: _Ids(),
      clock: () => DateTime.utc(2026, 9, 29, 12),
    ),
  );
}

Category _category(String id, String name) {
  final DateTime now = DateTime.utc(2026, 9, 29, 12);
  return Category(
    id: id,
    name: name,
    sortOrder: 0,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _Ids implements IdGenerator {
  int count = 0;

  @override
  String generate() {
    count += 1;
    return '00000000-0000-4000-8000-${count.toString().padLeft(12, '0')}';
  }
}

class _CategoryFake implements CategoryRepository {
  final List<Category> values = <Category>[];
  bool failLists = false;
  Completer<void>? createBarrier;

  @override
  Future<void> create(Category category) async {
    await createBarrier?.future;
    values.add(category);
  }

  @override
  Future<Category?> findById(String id) async {
    for (final Category category in values) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  @override
  Future<List<Category>> listAll() async {
    if (failLists) {
      throw const PersistenceError('No se pudo leer el catálogo.');
    }
    return List<Category>.of(values);
  }

  @override
  Future<int> nextSortOrder() async => values.length;

  @override
  Future<void> reorder(String id, int newIndex, DateTime updatedAt) async {
    final int oldIndex = values.indexWhere((Category item) => item.id == id);
    final Category value = values.removeAt(oldIndex);
    values.insert(newIndex.clamp(0, values.length), value);
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
  Future<Product?> findById(String id) async => null;

  @override
  Future<List<Product>> listAll({String? categoryId}) async {
    final List<Product> result = values
        .where(
          (Product value) =>
              categoryId == null || value.categoryId == categoryId,
        )
        .toList();
    result.sort(
      (Product left, Product right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return result;
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
