import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../domain/errors/domain_error.dart';
import 'migrations/migration.dart';
import 'migrations/migration_runner.dart';

typedef MigrationLoader = Future<List<Migration>> Function();

class AppDatabase {
  factory AppDatabase({
    String? databasePath,
    MigrationLoader? migrationLoader,
    MigrationRunner migrationRunner = const MigrationRunner(),
  }) {
    return AppDatabase._internal(
      databasePath,
      migrationLoader ?? _loadBundledMigrations,
      migrationRunner,
    );
  }

  AppDatabase._internal(
    this._databasePath,
    this._migrationLoader,
    this._migrationRunner,
  );

  static const String fileName = 'cafe_pos.db';

  final String? _databasePath;
  final MigrationLoader _migrationLoader;
  final MigrationRunner _migrationRunner;
  Database? _database;

  Future<Database> get database async {
    return _database ?? initialize();
  }

  Future<Database> initialize() async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    final String resolvedPath =
        _databasePath ?? path.join(await getDatabasesPath(), fileName);
    final Database opened = await openDatabase(
      resolvedPath,
      singleInstance: false,
      onConfigure: (Database database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
    );
    try {
      await _migrationRunner.migrate(opened, await _migrationLoader());
      _database = opened;
      return opened;
    } on Object {
      await opened.close();
      rethrow;
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  static Future<List<Migration>> _loadBundledMigrations() async {
    try {
      return <Migration>[
        Migration(
          version: 1,
          sql: await rootBundle.loadString('database/001_initial_schema.sql'),
        ),
      ];
    } on FlutterError catch (error) {
      throw PersistenceError('No se pudo cargar el esquema inicial: $error');
    }
  }
}
