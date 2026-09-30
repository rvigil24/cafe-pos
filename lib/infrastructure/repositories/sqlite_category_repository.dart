import 'package:sqflite/sqflite.dart';

import '../../domain/entities/category.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/category_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqliteCategoryRepository implements CategoryRepository {
  const SqliteCategoryRepository(this._provider);

  final AppDatabase _provider;

  @override
  Future<List<Category>> listAll() async {
    final Database database = await _provider.database;
    final List<Map<String, Object?>> rows = await database.query(
      'categories',
      orderBy: 'sort_order ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Category?> findById(String id) async {
    final Database database = await _provider.database;
    final List<Map<String, Object?>> rows = await database.query(
      'categories',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<int> nextSortOrder() async {
    final Database database = await _provider.database;
    final int? maximum = Sqflite.firstIntValue(
      await database.rawQuery('SELECT MAX(sort_order) FROM categories'),
    );
    return (maximum ?? -1) + 1;
  }

  @override
  Future<void> create(Category category) async {
    try {
      final Database database = await _provider.database;
      await database.insert('categories', _toRow(category));
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo crear la categoría.');
    }
  }

  @override
  Future<void> update(Category category) async {
    try {
      final Database database = await _provider.database;
      final int count = await database.update(
        'categories',
        <String, Object?>{
          'name': category.name,
          'sort_order': category.sortOrder,
          'is_active': boolToInt(category.isActive),
          'updated_at': timestamp(category.updatedAt),
        },
        where: 'id = ?',
        whereArgs: <Object?>[category.id],
      );
      if (count != 1) {
        throw const EntityNotFoundError('La categoría ya no existe.');
      }
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo guardar la categoría.');
    }
  }

  @override
  Future<void> reorder(String id, int newIndex, DateTime updatedAt) async {
    final Database database = await _provider.database;
    await database.transaction<void>((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'categories',
        columns: <String>['id'],
        orderBy: 'sort_order ASC, name COLLATE NOCASE ASC',
      );
      final List<String> ids = rows
          .map((Map<String, Object?> row) => row['id']! as String)
          .toList();
      if (!ids.remove(id)) {
        throw const EntityNotFoundError('La categoría ya no existe.');
      }
      ids.insert(newIndex.clamp(0, ids.length), id);
      final Batch batch = transaction.batch();
      for (int index = 0; index < ids.length; index += 1) {
        batch.update(
          'categories',
          <String, Object?>{
            'sort_order': index,
            'updated_at': timestamp(updatedAt),
          },
          where: 'id = ?',
          whereArgs: <Object?>[ids[index]],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Category _fromRow(Map<String, Object?> row) {
    return Category(
      id: row['id']! as String,
      name: row['name']! as String,
      sortOrder: row['sort_order']! as int,
      isActive: intToBool(row['is_active']),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  Map<String, Object?> _toRow(Category category) {
    return <String, Object?>{
      'id': category.id,
      'name': category.name,
      'sort_order': category.sortOrder,
      'is_active': boolToInt(category.isActive),
      'created_at': timestamp(category.createdAt),
      'updated_at': timestamp(category.updatedAt),
    };
  }
}
