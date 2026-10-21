import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../domain/errors/domain_error.dart';
import 'migrations/migration.dart';
import 'migrations/migration_runner.dart';

typedef MigrationLoader = Future<List<Migration>> Function();

class DatabaseMaintenanceSession {
  DatabaseMaintenanceSession._(this._owner, this.path);

  final AppDatabase _owner;
  final String path;

  Future<void> close() => _owner._closeUnlocked();

  Future<Database> reopen() => _owner._initializeUnlocked();
}

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
  Future<void> _operationTail = Future<void>.value();
  Database? _database;
  String? _resolvedPath;

  Future<Database> get database async {
    return _database ?? initialize();
  }

  Future<Database> initialize() async {
    return _serialize<Database>(_initializeUnlocked);
  }

  Future<T> use<T>(Future<T> Function(Database database) operation) {
    return _serialize<T>(() async {
      return operation(await _initializeUnlocked());
    });
  }

  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) operation,
  ) {
    return use<T>((Database database) => database.transaction<T>(operation));
  }

  Future<T> maintain<T>(
    Future<T> Function(DatabaseMaintenanceSession session) operation,
  ) {
    return _serialize<T>(() async {
      final DatabaseMaintenanceSession session = DatabaseMaintenanceSession._(
        this,
        await _resolvePath(),
      );
      try {
        return await operation(session);
      } finally {
        await _initializeUnlocked();
      }
    });
  }

  Future<Database> _initializeUnlocked() async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    final String resolvedPath = await _resolvePath();
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
    await _serialize<void>(_closeUnlocked);
  }

  Future<void> _closeUnlocked() async {
    await _database?.close();
    _database = null;
  }

  Future<String> _resolvePath() async {
    return _resolvedPath ??=
        _databasePath ?? path.join(await getDatabasesPath(), fileName);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) async {
    final Future<void> previous = _operationTail;
    final Completer<void> release = Completer<void>();
    _operationTail = release.future;
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
    }
  }

  static Future<List<Migration>> _loadBundledMigrations() async {
    try {
      return <Migration>[
        Migration(
          version: 1,
          sql: await rootBundle.loadString('database/001_initial_schema.sql'),
        ),
        Migration(
          version: 2,
          sql: await rootBundle.loadString(
            'database/002_add_credit_card_payment_method.sql',
          ),
        ),
      ];
    } on FlutterError catch (error) {
      throw PersistenceError('No se pudo cargar el esquema inicial: $error');
    }
  }
}
