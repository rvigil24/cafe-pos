import 'package:flutter/foundation.dart' hide Category;

import '../../../application/use_cases/catalog_use_cases.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/errors/domain_error.dart';

enum CatalogStatus { loading, ready, error }

class CatalogController extends ChangeNotifier {
  CatalogController(this._useCases);

  final CatalogUseCases _useCases;

  CatalogStatus status = CatalogStatus.loading;
  List<Category> categories = <Category>[];
  List<Product> products = <Product>[];
  String? selectedCategoryId;
  String? errorMessage;
  bool isSaving = false;

  List<Product> get selectedProducts => products
      .where((Product product) => product.categoryId == selectedCategoryId)
      .toList(growable: false);

  Category? get selectedCategory {
    for (final Category category in categories) {
      if (category.id == selectedCategoryId) {
        return category;
      }
    }
    return null;
  }

  Future<void> load() async {
    status = CatalogStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await _reload();
      status = CatalogStatus.ready;
    } on Object catch (error) {
      status = CatalogStatus.error;
      errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  void selectCategory(String id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  Future<bool> createCategory(String name) {
    return _write(() async {
      final Category category = await _useCases.createCategory(name);
      selectedCategoryId = category.id;
    });
  }

  Future<bool> renameCategory(Category category, String name) {
    return _write(() => _useCases.renameCategory(category, name));
  }

  Future<bool> setCategoryActive(Category category, bool active) {
    return _write(() => _useCases.setCategoryActive(category, active));
  }

  Future<bool> moveCategory(Category category, int delta) {
    final int currentIndex = categories.indexOf(category);
    return _write(
      () => _useCases.reorderCategory(category.id, currentIndex + delta),
    );
  }

  Future<bool> createProduct({
    required String categoryId,
    required String name,
    required String price,
  }) {
    return _write(
      () => _useCases.createProduct(
        categoryId: categoryId,
        name: name,
        price: price,
      ),
    );
  }

  Future<bool> editProduct({
    required Product product,
    required String categoryId,
    required String name,
    required String price,
  }) {
    return _write(
      () => _useCases.editProduct(
        product: product,
        categoryId: categoryId,
        name: name,
        price: price,
      ),
    );
  }

  Future<bool> setProductActive(Product product, bool active) {
    return _write(() => _useCases.setProductActive(product, active));
  }

  Future<bool> setProductAvailable(Product product, bool available) {
    return _write(() => _useCases.setProductAvailable(product, available));
  }

  Future<bool> _write(Future<void> Function() operation) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      await _reload();
      return true;
    } on Object catch (error) {
      errorMessage = _messageFor(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _reload() async {
    categories = await _useCases.listCategories();
    products = await _useCases.listProducts();
    if (categories.isEmpty) {
      selectedCategoryId = null;
    } else if (!categories.any(
      (Category category) => category.id == selectedCategoryId,
    )) {
      selectedCategoryId = categories.first.id;
    }
  }

  String _messageFor(Object error) {
    if (error is DomainError) {
      return error.message;
    }
    return 'No se pudo cargar el catálogo. Intenta nuevamente.';
  }
}
