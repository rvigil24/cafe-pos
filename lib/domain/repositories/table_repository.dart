import '../entities/cafe_table.dart';

abstract interface class TableRepository {
  Future<List<CafeTable>> listAll();

  Future<CafeTable?> findById(String id);

  Future<int> nextSortOrder();

  Future<void> create(CafeTable table);

  Future<void> update(CafeTable table);

  Future<void> reorder(String id, int newIndex, DateTime updatedAt);
}
