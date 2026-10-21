import 'package:sqflite/sqflite.dart';

import '../../domain/errors/domain_error.dart';
import '../database/app_database.dart';

class SqliteExecutor {
  SqliteExecutor.database(this._database) : _executor = null;

  SqliteExecutor.direct(DatabaseExecutor executor)
    : _database = null,
      _executor = executor;

  final AppDatabase? _database;
  final DatabaseExecutor? _executor;

  Future<T> run<T>(Future<T> Function(DatabaseExecutor executor) operation) {
    final AppDatabase? database = _database;
    if (database != null) {
      return database.use<T>(operation);
    }
    return operation(_executor!);
  }

  Future<T> transaction<T>(
    Future<T> Function(DatabaseExecutor transaction) operation,
  ) {
    final AppDatabase? database = _database;
    if (database != null) {
      return database.transaction<T>(operation);
    }
    return operation(_executor!);
  }
}

Never translateDatabaseError(DatabaseException error, String fallback) {
  final String message = error.toString().toLowerCase();
  if (message.contains('unique constraint failed')) {
    throw const DuplicateActiveNameError(
      'Ya existe un registro activo con ese nombre.',
    );
  }
  if (message.contains('foreign key constraint failed')) {
    throw const EntityNotFoundError('El registro relacionado ya no existe.');
  }
  throw PersistenceError(fallback);
}

int boolToInt(bool value) => value ? 1 : 0;

bool intToBool(Object? value) => value == 1;

String timestamp(DateTime value) => value.toUtc().toIso8601String();
