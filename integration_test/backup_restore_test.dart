import 'dart:async';
import 'dart:io';

import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/infrastructure/backup/backup_file_storage.dart';
import 'package:cafe_pos/infrastructure/backup/backup_validator.dart';
import 'package:cafe_pos/infrastructure/backup/sqlite_backup_repository.dart';
import 'package:cafe_pos/infrastructure/database/app_database.dart';
import 'package:cafe_pos/infrastructure/database/migrations/migration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory temporary;
  late Directory support;

  setUp(() async {
    root = Directory(
      path.join((await getTemporaryDirectory()).path, 'cafe_pos_backup_test'),
    );
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    temporary = Directory(path.join(root.path, 'temporary'));
    support = Directory(path.join(root.path, 'support'));
    await temporary.create(recursive: true);
    await support.create(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  testWidgets(
    'exports every data group and restores it with a preventive copy',
    (WidgetTester tester) async {
      final String livePath = path.join(root.path, 'live.db');
      final AppDatabase provider = AppDatabase(databasePath: livePath);
      final Database live = await provider.initialize();
      await _populate(live, businessName: 'Café respaldado');
      final _MemoryStorage storage = _MemoryStorage();
      final SqliteBackupRepository repository = _repository(
        provider,
        storage,
        temporary,
        support,
      );

      final export = await repository.exportBackup();
      expect(export, isNotNull);
      expect(storage.savedBytes, isNotNull);
      final File exported = File(path.join(root.path, 'exported.db'));
      await exported.writeAsBytes(storage.savedBytes!, flush: true);
      expect(
        (await const BackupValidator().validateFile(exported.path))
            .schemaVersion,
        2,
      );
      final Database exportedDatabase = await openDatabase(
        exported.path,
        readOnly: true,
        singleInstance: false,
      );
      expect(await _counts(exportedDatabase), <int>[1, 1, 1, 1, 1, 1, 3]);
      await exportedDatabase.close();

      await provider.use<void>((Database database) async {
        await database.update(
          'settings',
          <String, Object?>{'value': 'Datos actuales'},
          where: 'key = ?',
          whereArgs: <Object?>['business_name'],
        );
        await database.delete('payments');
        await database.update('orders', <String, Object?>{
          'status': 'OPEN',
          'paid_at': null,
        });
      });
      storage.source = BackupSource(
        name: 'cafe_pos_valid.db',
        bytes: storage.savedBytes!,
      );

      final restored = await repository.restoreBackup();
      expect(restored, isNotNull);
      expect(await File(restored!.preventiveBackupPath).exists(), isTrue);
      expect(await _businessName(await provider.database), 'Café respaldado');
      expect(await _counts(await provider.database), <int>[
        1,
        1,
        1,
        1,
        1,
        1,
        3,
      ]);
      final Database preventive = await openDatabase(
        restored.preventiveBackupPath,
        readOnly: true,
        singleInstance: false,
      );
      expect(await _businessName(preventive), 'Datos actuales');
      await preventive.close();
      await provider.close();
    },
  );

  testWidgets('rejects corrupt and future backups without changing live data', (
    WidgetTester tester,
  ) async {
    final AppDatabase provider = AppDatabase(
      databasePath: path.join(root.path, 'live.db'),
    );
    await provider.initialize();
    await provider.use<void>((Database database) async {
      await database.update(
        'settings',
        <String, Object?>{'value': 'Datos seguros'},
        where: 'key = ?',
        whereArgs: <Object?>['business_name'],
      );
    });
    final _MemoryStorage storage = _MemoryStorage(
      source: BackupSource(
        name: 'corrupt.db',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );
    final SqliteBackupRepository repository = _repository(
      provider,
      storage,
      temporary,
      support,
    );
    await expectLater(
      repository.restoreBackup(),
      throwsA(isA<BackupValidationError>()),
    );
    expect(await _businessName(await provider.database), 'Datos seguros');

    final String futurePath = path.join(root.path, 'future.db');
    final AppDatabase futureProvider = AppDatabase(databasePath: futurePath);
    await futureProvider.initialize();
    await futureProvider.use<void>((Database database) async {
      await database.execute('PRAGMA user_version = 99');
    });
    await futureProvider.close();
    storage.source = BackupSource(
      name: 'future.db',
      bytes: await File(futurePath).readAsBytes(),
    );
    await expectLater(
      repository.restoreBackup(),
      throwsA(isA<BackupValidationError>()),
    );
    expect(await _businessName(await provider.database), 'Datos seguros');

    final String incompletePath = path.join(root.path, 'incomplete.db');
    final Database incomplete = await openDatabase(
      incompletePath,
      singleInstance: false,
    );
    await incomplete.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT, updated_at TEXT)',
    );
    await incomplete.execute('PRAGMA user_version = 2');
    await incomplete.close();
    storage.source = BackupSource(
      name: 'incomplete.db',
      bytes: await File(incompletePath).readAsBytes(),
    );
    await expectLater(
      repository.restoreBackup(),
      throwsA(isA<BackupValidationError>()),
    );
    expect(await _businessName(await provider.database), 'Datos seguros');
    await provider.close();
  });

  testWidgets('migrates a valid version-one backup exactly once', (
    WidgetTester tester,
  ) async {
    final String oldPath = path.join(root.path, 'version_one.db');
    final AppDatabase oldProvider = AppDatabase(
      databasePath: oldPath,
      migrationLoader: () async => <Migration>[
        Migration(
          version: 1,
          sql: await rootBundle.loadString('database/001_initial_schema.sql'),
        ),
      ],
    );
    await oldProvider.initialize();
    await oldProvider.use<void>((Database database) async {
      await database.update(
        'settings',
        <String, Object?>{'value': 'Base versión uno'},
        where: 'key = ?',
        whereArgs: <Object?>['business_name'],
      );
    });
    await oldProvider.close();

    final AppDatabase provider = AppDatabase(
      databasePath: path.join(root.path, 'live.db'),
    );
    await provider.initialize();
    final _MemoryStorage storage = _MemoryStorage(
      source: BackupSource(
        name: 'version_one.db',
        bytes: await File(oldPath).readAsBytes(),
      ),
    );
    final SqliteBackupRepository repository = _repository(
      provider,
      storage,
      temporary,
      support,
    );

    await repository.restoreBackup();
    expect(await _businessName(await provider.database), 'Base versión uno');
    expect(
      Sqflite.firstIntValue(
        await (await provider.database).rawQuery('PRAGMA user_version'),
      ),
      2,
    );
    await provider.close();
  });

  testWidgets('rolls back when post-replacement validation fails', (
    WidgetTester tester,
  ) async {
    final AppDatabase provider = AppDatabase(
      databasePath: path.join(root.path, 'live.db'),
    );
    await provider.initialize();
    await provider.use<void>((Database database) async {
      await database.update(
        'settings',
        <String, Object?>{'value': 'Base original'},
        where: 'key = ?',
        whereArgs: <Object?>['business_name'],
      );
    });
    final String candidatePath = path.join(root.path, 'candidate.db');
    final AppDatabase candidateProvider = AppDatabase(
      databasePath: candidatePath,
    );
    await candidateProvider.initialize();
    await candidateProvider.use<void>((Database database) async {
      await database.update(
        'settings',
        <String, Object?>{'value': 'Base candidata'},
        where: 'key = ?',
        whereArgs: <Object?>['business_name'],
      );
    });
    await candidateProvider.close();
    final _MemoryStorage storage = _MemoryStorage(
      source: BackupSource(
        name: 'candidate.db',
        bytes: await File(candidatePath).readAsBytes(),
      ),
    );
    final SqliteBackupRepository repository = _repository(
      provider,
      storage,
      temporary,
      support,
      validator: _FailPostReplacementValidator(),
    );

    await expectLater(
      repository.restoreBackup(),
      throwsA(isA<BackupValidationError>()),
    );
    expect(await _businessName(await provider.database), 'Base original');
    await provider.close();
  });

  testWidgets('maintenance waits for an active database operation', (
    WidgetTester tester,
  ) async {
    final AppDatabase provider = AppDatabase(
      databasePath: path.join(root.path, 'live.db'),
    );
    await provider.initialize();
    final Completer<void> release = Completer<void>();
    bool maintenanceEntered = false;
    final Future<void> operation = provider.use<void>((
      Database database,
    ) async {
      await release.future;
    });
    final Future<void> maintenance = provider.maintain<void>((_) async {
      maintenanceEntered = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(maintenanceEntered, isFalse);
    release.complete();
    await operation;
    await maintenance;
    expect(maintenanceEntered, isTrue);
    await provider.close();
  });
}

SqliteBackupRepository _repository(
  AppDatabase provider,
  _MemoryStorage storage,
  Directory temporary,
  Directory support, {
  BackupValidator validator = const BackupValidator(),
}) {
  return SqliteBackupRepository(
    provider,
    storage,
    validator: validator,
    temporaryDirectory: () async => temporary,
    supportDirectory: () async => support,
    clock: () => DateTime.utc(2026, 10, 20, 18, 30),
  );
}

Future<void> _populate(
  Database database, {
  required String businessName,
}) async {
  const String now = '2026-10-20T18:00:00.000Z';
  await database.transaction<void>((Transaction transaction) async {
    await transaction.update(
      'settings',
      <String, Object?>{'value': businessName},
      where: 'key = ?',
      whereArgs: <Object?>['business_name'],
    );
    await transaction.insert('categories', <String, Object?>{
      'id': 'category-1',
      'name': 'Café',
      'sort_order': 0,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await transaction.insert('products', <String, Object?>{
      'id': 'product-1',
      'category_id': 'category-1',
      'name': 'Espresso',
      'price_cents': 150,
      'is_available': 1,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await transaction.insert('cafe_tables', <String, Object?>{
      'id': 'table-1',
      'name': 'Mesa 1',
      'sort_order': 0,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await transaction.insert('orders', <String, Object?>{
      'id': 'order-1',
      'order_number': 1,
      'table_id': 'table-1',
      'table_name_snapshot': 'Mesa 1',
      'type': 'DINE_IN',
      'status': 'PAID',
      'total_cents': 150,
      'created_at': now,
      'updated_at': now,
      'paid_at': now,
    });
    await transaction.insert('order_items', <String, Object?>{
      'id': 'item-1',
      'order_id': 'order-1',
      'product_id': 'product-1',
      'product_name_snapshot': 'Espresso',
      'category_name_snapshot': 'Café',
      'quantity': 1,
      'unit_price_cents': 150,
      'created_at': now,
      'updated_at': now,
    });
    await transaction.insert('payments', <String, Object?>{
      'id': 'payment-1',
      'order_id': 'order-1',
      'method': 'CASH',
      'amount_cents': 150,
      'received_cents': 200,
      'created_at': now,
    });
  });
}

Future<List<int>> _counts(Database database) async {
  final List<int> values = <int>[];
  for (final String table in <String>[
    'categories',
    'products',
    'cafe_tables',
    'orders',
    'order_items',
    'payments',
    'settings',
  ]) {
    values.add(
      Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $table'),
      )!,
    );
  }
  return values;
}

Future<String> _businessName(Database database) async {
  final List<Map<String, Object?>> rows = await database.query(
    'settings',
    columns: <String>['value'],
    where: 'key = ?',
    whereArgs: <Object?>['business_name'],
  );
  return rows.single['value']! as String;
}

class _MemoryStorage implements BackupFileStorage {
  _MemoryStorage({this.source});

  BackupSource? source;
  Uint8List? savedBytes;

  @override
  Future<BackupSource?> pick() async => source;

  @override
  Future<Uri?> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    savedBytes = Uint8List.fromList(bytes);
    return Uri.parse('memory:///$fileName');
  }
}

class _FailPostReplacementValidator extends BackupValidator {
  int _currentValidations = 0;

  @override
  Future<BackupValidationSummary> validateDatabase(
    DatabaseExecutor database, {
    bool requireCurrentVersion = false,
  }) async {
    final BackupValidationSummary result = await super.validateDatabase(
      database,
      requireCurrentVersion: requireCurrentVersion,
    );
    if (requireCurrentVersion && ++_currentValidations == 2) {
      throw const BackupValidationError('Falla posterior inyectada.');
    }
    return result;
  }
}
