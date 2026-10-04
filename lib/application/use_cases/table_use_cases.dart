import '../../domain/entities/cafe_table.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/table_repository.dart';
import '../services/id_generator.dart';

typedef TableClock = DateTime Function();

class TableUseCases {
  const TableUseCases({
    required TableRepository tables,
    required IdGenerator ids,
    required TableClock clock,
  }) : this._internal(tables, ids, clock);

  const TableUseCases._internal(this._tables, this._ids, this._clock);

  final TableRepository _tables;
  final IdGenerator _ids;
  final TableClock _clock;

  Future<List<CafeTable>> listTables() => _tables.listAll();

  Future<CafeTable> createTable(String rawName) async {
    final DateTime now = _utcNow();
    final CafeTable table = CafeTable(
      id: _ids.generate(),
      name: _validName(rawName),
      sortOrder: await _tables.nextSortOrder(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await _tables.create(table);
    return table;
  }

  Future<void> renameTable(CafeTable table, String rawName) {
    return _tables.update(
      table.copyWith(name: _validName(rawName), updatedAt: _utcNow()),
    );
  }

  Future<void> setTableActive(CafeTable table, bool active) {
    return _tables.update(
      table.copyWith(isActive: active, updatedAt: _utcNow()),
    );
  }

  Future<void> reorderTable(String id, int newIndex) {
    return _tables.reorder(id, newIndex, _utcNow());
  }

  String _validName(String rawName) {
    final String name = rawName.trim();
    if (name.isEmpty) {
      throw const ValidationError('Ingresa un nombre.', field: 'name');
    }
    return name;
  }

  DateTime _utcNow() => _clock().toUtc();
}
