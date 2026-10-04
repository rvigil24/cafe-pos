import 'package:sqflite/sqflite.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/settings_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqliteSettingsRepository implements SettingsRepository {
  SqliteSettingsRepository(AppDatabase provider)
    : _executor = (() => provider.database);

  SqliteSettingsRepository.executor(DatabaseExecutor executor)
    : _executor = (() async => executor);

  final Future<DatabaseExecutor> Function() _executor;

  @override
  Future<AppSettings> load() async {
    final DatabaseExecutor database = await _executor();
    final List<Map<String, Object?>> rows = await database.query('settings');
    final Map<String, String> values = <String, String>{
      for (final Map<String, Object?> row in rows)
        row['key']! as String: row['value']! as String,
    };
    final int? lastOrderNumber = int.tryParse(
      values['last_order_number'] ?? '',
    );
    if (values['business_name'] == null ||
        values['timezone'] == null ||
        lastOrderNumber == null) {
      throw const PersistenceError(
        'La configuración local está incompleta o dañada.',
      );
    }
    return AppSettings(
      businessName: values['business_name']!,
      timezone: values['timezone']!,
      lastOrderNumber: lastOrderNumber,
    );
  }

  @override
  Future<void> setValue(String key, String value, DateTime updatedAt) async {
    final DatabaseExecutor database = await _executor();
    final int count = await database.update(
      'settings',
      <String, Object?>{'value': value, 'updated_at': timestamp(updatedAt)},
      where: 'key = ?',
      whereArgs: <Object?>[key],
    );
    if (count != 1) {
      throw EntityNotFoundError('No existe el ajuste "$key".');
    }
  }

  @override
  Future<int> allocateNextOrderNumber(DateTime updatedAt) async {
    final DatabaseExecutor database = await _executor();
    final int count = await database.rawUpdate(
      '''
      UPDATE settings
      SET value = CAST(value AS INTEGER) + 1, updated_at = ?
      WHERE key = 'last_order_number'
        AND length(value) > 0
        AND value NOT GLOB '*[^0-9]*'
        AND CAST(value AS INTEGER) >= 0
      ''',
      <Object?>[timestamp(updatedAt)],
    );
    if (count != 1) {
      throw const PersistenceError('No se pudo reservar el número de orden.');
    }
    final List<Map<String, Object?>> rows = await database.query(
      'settings',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>['last_order_number'],
      limit: 1,
    );
    final int? value = rows.isEmpty
        ? null
        : int.tryParse(rows.single['value']! as String);
    if (value == null || value <= 0) {
      throw const PersistenceError('El número de orden local está dañado.');
    }
    return value;
  }
}
