import 'package:sqflite/sqflite.dart';

import '../../domain/errors/domain_error.dart';

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
