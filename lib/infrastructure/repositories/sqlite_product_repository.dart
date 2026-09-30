import 'package:sqflite/sqflite.dart';

import '../../domain/entities/product.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/product_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqliteProductRepository implements ProductRepository {
  const SqliteProductRepository(this._provider);

  final AppDatabase _provider;

  @override
  Future<List<Product>> listAll({String? categoryId}) async {
    final Database database = await _provider.database;
    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: categoryId == null ? null : 'category_id = ?',
      whereArgs: categoryId == null ? null : <Object?>[categoryId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<Product>> listSellable({String? categoryId}) async {
    final Database database = await _provider.database;
    final List<Object?> arguments = <Object?>[];
    final StringBuffer where = StringBuffer(
      'p.is_active = 1 AND p.is_available = 1 AND c.is_active = 1',
    );
    if (categoryId != null) {
      where.write(' AND p.category_id = ?');
      arguments.add(categoryId);
    }
    final List<Map<String, Object?>> rows = await database.rawQuery('''
      SELECT p.* FROM products p
      INNER JOIN categories c ON c.id = p.category_id
      WHERE $where
      ORDER BY p.name COLLATE NOCASE ASC
      ''', arguments);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Product?> findById(String id) async {
    final Database database = await _provider.database;
    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> create(Product product) async {
    try {
      final Database database = await _provider.database;
      await database.insert('products', _toRow(product));
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo crear el producto.');
    }
  }

  @override
  Future<void> update(Product product) async {
    try {
      final Database database = await _provider.database;
      final int count = await database.update(
        'products',
        <String, Object?>{
          'category_id': product.categoryId,
          'name': product.name,
          'price_cents': product.priceCents,
          'is_available': boolToInt(product.isAvailable),
          'is_active': boolToInt(product.isActive),
          'updated_at': timestamp(product.updatedAt),
        },
        where: 'id = ?',
        whereArgs: <Object?>[product.id],
      );
      if (count != 1) {
        throw const EntityNotFoundError('El producto ya no existe.');
      }
    } on DatabaseException catch (error) {
      translateDatabaseError(error, 'No se pudo guardar el producto.');
    }
  }

  Product _fromRow(Map<String, Object?> row) {
    return Product(
      id: row['id']! as String,
      categoryId: row['category_id']! as String,
      name: row['name']! as String,
      priceCents: row['price_cents']! as int,
      isAvailable: intToBool(row['is_available']),
      isActive: intToBool(row['is_active']),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  Map<String, Object?> _toRow(Product product) {
    return <String, Object?>{
      'id': product.id,
      'category_id': product.categoryId,
      'name': product.name,
      'price_cents': product.priceCents,
      'is_available': boolToInt(product.isAvailable),
      'is_active': boolToInt(product.isActive),
      'created_at': timestamp(product.createdAt),
      'updated_at': timestamp(product.updatedAt),
    };
  }
}
