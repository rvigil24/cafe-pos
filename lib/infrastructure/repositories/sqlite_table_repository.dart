import 'package:sqflite/sqflite.dart';

import '../../domain/entities/cafe_table.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/table_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqliteTableRepository implements TableRepository {
  const SqliteTableRepository(this._provider);

  final AppDatabase _provider;

  @override
  Future<List<CafeTable>> listAll() async {
    final Database database = await _provider.database;
    final List<Map<String, Object?>> rows = await database.query(
      'cafe_tables',
      orderBy: 'sort_order ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<CafeTable?> findById(String id) async {
    final Database database = await _provider.database;
    final List<Map<String, Object?>> rows = await database.query(
      'cafe_tables',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> create(CafeTable table) async {
    try {
      final Database database = await _provider.database;
      await database.insert('cafe_tables', _toRow(table));
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo crear la mesa.');
    }
  }

  @override
  Future<void> update(CafeTable table) async {
    try {
      final Database database = await _provider.database;
      await database.transaction<void>((Transaction transaction) async {
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
      });
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo guardar la mesa.');
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
