import 'package:cafe_pos/application/use_cases/table_use_cases.dart';
import 'package:cafe_pos/domain/entities/cafe_table.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 3, 15);
  late FakeTableRepository tables;
  late TableUseCases useCases;

  setUp(() {
    tables = FakeTableRepository();
    useCases = TableUseCases(tables: tables, ids: FixedIds(), clock: () => now);
  });

  test('creates a trimmed active table at the next position', () async {
    final CafeTable first = await useCases.createTable(' Mesa 1 ');
    final CafeTable second = await useCases.createTable('Terraza');

    expect(first.name, 'Mesa 1');
    expect(first.isActive, isTrue);
    expect(first.sortOrder, 0);
    expect(second.sortOrder, 1);
    expect(first.createdAt, now);
  });

  test('rejects an empty table name', () async {
    await expectLater(
      useCases.createTable('  '),
      throwsA(isA<ValidationError>()),
    );
  });

  test('renames, reorders, and deactivates a table', () async {
    final CafeTable first = await useCases.createTable('Mesa 1');
    final CafeTable second = await useCases.createTable('Mesa 2');

    await useCases.renameTable(first, 'Ventana');
    await useCases.reorderTable(second.id, 0);
    await useCases.setTableActive((await tables.findById(first.id))!, false);

    expect(tables.values.first.id, second.id);
    expect((await tables.findById(first.id))!.name, 'Ventana');
    expect((await tables.findById(first.id))!.isActive, isFalse);
  });

  test('keeps an occupied-table error typed', () async {
    final CafeTable table = await useCases.createTable('Mesa 1');
    tables.updateError = const OccupiedTableError('Mesa ocupada.');

    await expectLater(
      useCases.setTableActive(table, false),
      throwsA(isA<OccupiedTableError>()),
    );
  });
}
