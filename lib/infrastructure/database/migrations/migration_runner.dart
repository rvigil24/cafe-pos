import 'package:sqflite/sqflite.dart';

import '../../../domain/errors/domain_error.dart';
import 'migration.dart';

class MigrationRunner {
  const MigrationRunner();

  Future<void> migrate(Database database, List<Migration> migrations) async {
    final List<Migration> ordered = List<Migration>.of(migrations)
      ..sort((Migration a, Migration b) => a.version.compareTo(b.version));
    for (int index = 0; index < ordered.length; index += 1) {
      if (ordered[index].version != index + 1) {
        throw const PersistenceError(
          'La secuencia de migraciones de la aplicación no es válida.',
        );
      }
    }
    final int currentVersion = Sqflite.firstIntValue(
      await database.rawQuery('PRAGMA user_version'),
    )!;
    final int supportedVersion = ordered.isEmpty ? 0 : ordered.last.version;
    if (currentVersion > supportedVersion) {
      throw PersistenceError(
        'La base de datos usa la versión $currentVersion, pero esta aplicación '
        'solo admite hasta la versión $supportedVersion.',
      );
    }
    final List<Migration> pending = ordered
        .where((Migration migration) => migration.version > currentVersion)
        .toList();
    if (pending.isEmpty) {
      return;
    }

    try {
      await database.transaction<void>((Transaction transaction) async {
        for (final Migration migration in pending) {
          for (final String statement in splitSqlStatements(migration.sql)) {
            await transaction.execute(statement);
          }
          await transaction.execute(
            'PRAGMA user_version = ${migration.version}',
          );
        }
      });
    } on DatabaseException catch (error) {
      throw PersistenceError('No se pudo actualizar la base de datos: $error');
    }
  }
}

List<String> splitSqlStatements(String script) {
  return script
      .split(';')
      .map((String statement) => statement.trim())
      .where((String statement) => statement.isNotEmpty)
      .toList(growable: false);
}
