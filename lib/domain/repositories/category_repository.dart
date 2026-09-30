import '../entities/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> listAll();

  Future<Category?> findById(String id);

  Future<int> nextSortOrder();

  Future<void> create(Category category);

  Future<void> update(Category category);

  Future<void> reorder(String id, int newIndex, DateTime updatedAt);
}
