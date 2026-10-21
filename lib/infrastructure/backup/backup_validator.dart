import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../domain/errors/domain_error.dart';

class BackupValidationSummary {
  const BackupValidationSummary(this.schemaVersion);

  final int schemaVersion;
}

class BackupValidator {
  const BackupValidator({this.minimumVersion = 1, this.currentVersion = 2});

  final int minimumVersion;
  final int currentVersion;

  static const List<int> _sqliteHeader = <int>[
    83,
    81,
    76,
    105,
    116,
    101,
    32,
    102,
    111,
    114,
    109,
    97,
    116,
    32,
    51,
    0,
  ];

  static const Map<String, Set<String>> _requiredColumns =
      <String, Set<String>>{
        'categories': <String>{
          'id',
          'name',
          'sort_order',
          'is_active',
          'created_at',
          'updated_at',
        },
        'products': <String>{
          'id',
          'category_id',
          'name',
          'price_cents',
          'is_available',
          'is_active',
          'created_at',
          'updated_at',
        },
        'cafe_tables': <String>{
          'id',
          'name',
          'sort_order',
          'is_active',
          'created_at',
          'updated_at',
        },
        'orders': <String>{
          'id',
          'order_number',
          'table_id',
          'table_name_snapshot',
          'type',
          'status',
          'total_cents',
          'created_at',
          'updated_at',
          'paid_at',
          'cancelled_at',
          'cancellation_reason',
        },
        'order_items': <String>{
          'id',
          'order_id',
          'product_id',
          'product_name_snapshot',
          'category_name_snapshot',
          'quantity',
          'unit_price_cents',
          'note',
          'created_at',
          'updated_at',
        },
        'payments': <String>{
          'id',
          'order_id',
          'method',
          'amount_cents',
          'received_cents',
          'reference',
          'created_at',
        },
        'settings': <String>{'key', 'value', 'updated_at'},
      };

  static const Set<String> _requiredIndexes = <String>{
    'categories_active_name_uq',
    'products_category_idx',
    'products_active_available_idx',
    'cafe_tables_active_name_uq',
    'one_open_order_per_table_uq',
    'orders_status_idx',
    'orders_created_at_idx',
    'orders_paid_at_idx',
    'order_items_order_idx',
    'order_items_product_idx',
    'one_line_per_product_per_order_uq',
    'payments_created_at_idx',
    'payments_method_idx',
  };

  Future<BackupValidationSummary> validateFile(
    String filePath, {
    bool requireCurrentVersion = false,
  }) async {
    final File file = File(filePath);
    try {
      if (!await file.exists() || await file.length() < _sqliteHeader.length) {
        throw const BackupValidationError(
          'El archivo seleccionado no es un respaldo SQLite válido.',
        );
      }
      final List<int> header = await file.openRead(0, 16).first;
      if (header.length != _sqliteHeader.length ||
          !_sameBytes(header, _sqliteHeader)) {
        throw const BackupValidationError(
          'El archivo seleccionado no es un respaldo SQLite válido.',
        );
      }
      final Database database = await openDatabase(
        filePath,
        readOnly: true,
        singleInstance: false,
      );
      try {
        return await validateDatabase(
          database,
          requireCurrentVersion: requireCurrentVersion,
        );
      } finally {
        await database.close();
      }
    } on BackupValidationError {
      rethrow;
    } on Object {
      throw const BackupValidationError(
        'El respaldo está dañado o no se pudo leer.',
      );
    }
  }

  Future<BackupValidationSummary> validateDatabase(
    DatabaseExecutor database, {
    bool requireCurrentVersion = false,
  }) async {
    try {
      final int version =
          Sqflite.firstIntValue(
            await database.rawQuery('PRAGMA user_version'),
          ) ??
          0;
      final bool versionAllowed = requireCurrentVersion
          ? version == currentVersion
          : version >= minimumVersion && version <= currentVersion;
      if (!versionAllowed) {
        throw BackupValidationError(
          version > currentVersion
              ? 'El respaldo pertenece a una versión más nueva de Cafe POS.'
              : 'La versión del respaldo no es compatible.',
        );
      }

      final List<Map<String, Object?>> integrity = await database.rawQuery(
        'PRAGMA integrity_check',
      );
      if (integrity.length != 1 ||
          integrity.single.values.single.toString().toLowerCase() != 'ok') {
        throw const BackupValidationError(
          'El respaldo no superó la validación de integridad.',
        );
      }
      if ((await database.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
        throw const BackupValidationError(
          'El respaldo contiene relaciones de datos inválidas.',
        );
      }

      for (final MapEntry<String, Set<String>> entry
          in _requiredColumns.entries) {
        final List<Map<String, Object?>> columns = await database.rawQuery(
          'PRAGMA table_info(${entry.key})',
        );
        final Set<String> names = columns
            .map((Map<String, Object?> row) => row['name'] as String)
            .toSet();
        if (!names.containsAll(entry.value)) {
          throw const BackupValidationError(
            'El respaldo no contiene el esquema requerido por Cafe POS.',
          );
        }
      }
      final Set<String> indexes = (await database.query(
        'sqlite_master',
        columns: <String>['name'],
        where: "type = 'index'",
      )).map((Map<String, Object?> row) => row['name']! as String).toSet();
      if (!indexes.containsAll(_requiredIndexes)) {
        throw const BackupValidationError(
          'El respaldo no contiene los índices requeridos por Cafe POS.',
        );
      }
      final List<Map<String, Object?>> settingRows = await database.query(
        'settings',
        columns: <String>['key', 'value'],
        where: 'key IN (?, ?, ?)',
        whereArgs: <Object?>['business_name', 'timezone', 'last_order_number'],
      );
      final Map<String, String> settings = <String, String>{
        for (final Map<String, Object?> row in settingRows)
          row['key']! as String: row['value']! as String,
      };
      final int? lastOrderNumber = int.tryParse(
        settings['last_order_number'] ?? '',
      );
      if ((settings['business_name'] ?? '').trim().isEmpty ||
          settings['timezone'] != 'America/El_Salvador' ||
          lastOrderNumber == null ||
          lastOrderNumber < 0) {
        throw const BackupValidationError(
          'El respaldo contiene una configuración incompatible o dañada.',
        );
      }
      return BackupValidationSummary(version);
    } on BackupValidationError {
      rethrow;
    } on Object {
      throw const BackupValidationError(
        'El respaldo está dañado o no se pudo validar.',
      );
    }
  }

  bool _sameBytes(List<int> left, List<int> right) {
    for (int index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
