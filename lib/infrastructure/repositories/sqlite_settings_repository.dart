import 'package:sqflite/sqflite.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/settings_repository.dart';
import '../database/app_database.dart';
import 'sqlite_repository_support.dart';

class SqliteSettingsRepository implements SettingsRepository {
  const SqliteSettingsRepository(this._provider);

  final AppDatabase _provider;

  @override
  Future<AppSettings> load() async {
    final Database database = await _provider.database;
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
    final Database database = await _provider.database;
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
}
