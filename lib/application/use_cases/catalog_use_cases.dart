import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../shared/money/money_parser.dart';
import '../services/id_generator.dart';

typedef Clock = DateTime Function();

class CatalogUseCases {
  CatalogUseCases({
    required CategoryRepository categories,
    required ProductRepository products,
    required IdGenerator ids,
    required Clock clock,
  }) : this._internal(categories, products, ids, clock);

  CatalogUseCases._internal(
    this._categories,
    this._products,
    this._ids,
    this._clock,
  );

  final CategoryRepository _categories;
  final ProductRepository _products;
  final IdGenerator _ids;
  final Clock _clock;

  Future<List<Category>> listCategories() => _categories.listAll();

  Future<List<Product>> listProducts({String? categoryId}) {
    return _products.listAll(categoryId: categoryId);
  }

  Future<Category> createCategory(String rawName) async {
    final String name = _validName(rawName);
    final DateTime now = _utcNow();
    final Category category = Category(
      id: _ids.generate(),
      name: name,
      sortOrder: await _categories.nextSortOrder(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await _categories.create(category);
    return category;
  }

  Future<void> renameCategory(Category category, String rawName) {
    return _categories.update(
      category.copyWith(name: _validName(rawName), updatedAt: _utcNow()),
    );
  }

  Future<void> setCategoryActive(Category category, bool isActive) {
    return _categories.update(
      category.copyWith(isActive: isActive, updatedAt: _utcNow()),
    );
  }

  Future<void> reorderCategory(String id, int newIndex) {
    return _categories.reorder(id, newIndex, _utcNow());
  }

  Future<Product> createProduct({
    required String categoryId,
    required String name,
    required String price,
  }) async {
    await _requireCategory(categoryId);
    final DateTime now = _utcNow();
    final Product product = Product(
      id: _ids.generate(),
      categoryId: categoryId,
      name: _validName(name),
      priceCents: parsePriceCents(price),
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await _products.create(product);
    return product;
  }

  Future<void> editProduct({
    required Product product,
    required String categoryId,
    required String name,
    required String price,
  }) async {
    await _requireCategory(categoryId);
    await _products.update(
      product.copyWith(
        categoryId: categoryId,
        name: _validName(name),
        priceCents: parsePriceCents(price),
        updatedAt: _utcNow(),
      ),
    );
  }

  Future<void> setProductActive(Product product, bool isActive) {
    return _products.update(
      product.copyWith(isActive: isActive, updatedAt: _utcNow()),
    );
  }

  Future<void> setProductAvailable(Product product, bool isAvailable) {
    return _products.update(
      product.copyWith(isAvailable: isAvailable, updatedAt: _utcNow()),
    );
  }

  String _validName(String rawName) {
    final String name = rawName.trim();
    if (name.isEmpty) {
      throw const ValidationError('Ingresa un nombre.', field: 'name');
    }
    return name;
  }

  Future<void> _requireCategory(String id) async {
    if (await _categories.findById(id) == null) {
      throw const EntityNotFoundError('La categoría ya no existe.');
    }
  }

  DateTime _utcNow() => _clock().toUtc();
}
