import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> listAll({String? categoryId});

  Future<List<Product>> listSellable({String? categoryId});

  Future<Product?> findById(String id);

  Future<void> create(Product product);

  Future<void> update(Product product);
}
