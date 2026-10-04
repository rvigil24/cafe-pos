import 'package:sqflite/sqflite.dart';

import '../../domain/entities/cafe_table.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/table_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqliteTableRepository implements TableRepository {
  SqliteTableRepository(AppDatabase provider)
    : _executor = (() => provider.database),
      _database = provider;

  SqliteTableRepository.executor(DatabaseExecutor executor)
    : _executor = (() async => executor),
      _database = null;

  final Future<DatabaseExecutor> Function() _executor;
  final AppDatabase? _database;

  @override
  Future<List<CafeTable>> listAll() async {
    final DatabaseExecutor database = await _executor();
    final List<Map<String, Object?>> rows = await database.query(
      'cafe_tables',
      orderBy: 'sort_order ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<CafeTable?> findById(String id) async {
    final DatabaseExecutor database = await _executor();
    final List<Map<String, Object?>> rows = await database.query(
      'cafe_tables',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<int> nextSortOrder() async {
    final DatabaseExecutor database = await _executor();
    final int? maximum = Sqflite.firstIntValue(
      await database.rawQuery('SELECT MAX(sort_order) FROM cafe_tables'),
    );
    return (maximum ?? -1) + 1;
  }

  @override
  Future<void> create(CafeTable table) async {
    try {
      final DatabaseExecutor database = await _executor();
      await database.insert('cafe_tables', _toRow(table));
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo crear la mesa.');
    }
  }

  @override
  Future<void> update(CafeTable table) async {
    try {
      Future<void> operation(DatabaseExecutor transaction) async {
        if (!table.isActive) {
          final int openOrders = Sqflite.firstIntValue(
            await transaction.rawQuery(
              "SELECT COUNT(*) FROM orders WHERE table_id = ? AND status = 'OPEN'",
              <Object?>[table.id],
            ),
          )!;
          if (openOrders > 0) {
            throw const OccupiedTableError(
              'No se puede desactivar una mesa con una orden abierta.',
            );
          }
        }
        final int count = await transaction.update(
          'cafe_tables',
          <String, Object?>{
            'name': table.name,
            'sort_order': table.sortOrder,
            'is_active': boolToInt(table.isActive),
            'updated_at': timestamp(table.updatedAt),
          },
          where: 'id = ?',
          whereArgs: <Object?>[table.id],
        );
        if (count != 1) {
          throw const EntityNotFoundError('La mesa ya no existe.');
        }
      }

      final AppDatabase? provider = _database;
      if (provider == null) {
        await operation(await _executor());
      } else {
        final Database database = await provider.database;
        await database.transaction<void>(operation);
      }
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo guardar la mesa.');
    }
  }

  @override
  Future<void> reorder(String id, int newIndex, DateTime updatedAt) async {
    Future<void> operation(DatabaseExecutor transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'cafe_tables',
        columns: <String>['id'],
        orderBy: 'sort_order ASC, name COLLATE NOCASE ASC',
      );
      final List<String> ids = rows
          .map((Map<String, Object?> row) => row['id']! as String)
          .toList();
      if (!ids.remove(id)) {
        throw const EntityNotFoundError('La mesa ya no existe.');
      }
      ids.insert(newIndex.clamp(0, ids.length), id);
      final Batch batch = transaction.batch();
      for (int index = 0; index < ids.length; index += 1) {
        batch.update(
          'cafe_tables',
          <String, Object?>{
            'sort_order': index,
            'updated_at': timestamp(updatedAt),
          },
          where: 'id = ?',
          whereArgs: <Object?>[ids[index]],
        );
      }
      await batch.commit(noResult: true);
    }

    final AppDatabase? provider = _database;
    if (provider == null) {
      await operation(await _executor());
    } else {
      final Database database = await provider.database;
      await database.transaction<void>(operation);
    }
  }

  CafeTable _fromRow(Map<String, Object?> row) {
    return CafeTable(
      id: row['id']! as String,
      name: row['name']! as String,
      sortOrder: row['sort_order']! as int,
      isActive: intToBool(row['is_active']),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  Map<String, Object?> _toRow(CafeTable table) {
    return <String, Object?>{
      'id': table.id,
      'name': table.name,
      'sort_order': table.sortOrder,
      'is_active': boolToInt(table.isActive),
      'created_at': timestamp(table.createdAt),
      'updated_at': timestamp(table.updatedAt),
    };
  }
}
