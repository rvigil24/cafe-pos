import 'package:flutter/foundation.dart';

import '../../../application/use_cases/table_use_cases.dart';
import '../../../domain/entities/cafe_table.dart';
import '../../../domain/errors/domain_error.dart';

enum TableStatus { loading, ready, error }

class TableController extends ChangeNotifier {
  TableController(this._tables);

  final TableUseCases _tables;

  TableStatus status = TableStatus.loading;
  List<CafeTable> tables = <CafeTable>[];
  String? errorMessage;
  bool isSaving = false;

  Future<void> load() async {
    status = TableStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      tables = await _tables.listTables();
      status = TableStatus.ready;
    } on Object catch (error) {
      status = TableStatus.error;
      errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  Future<bool> createTable(String name) {
    return _write(() => _tables.createTable(name));
  }

  Future<bool> renameTable(CafeTable table, String name) {
    return _write(() => _tables.renameTable(table, name));
  }

  Future<bool> setTableActive(CafeTable table, bool active) {
    return _write(() => _tables.setTableActive(table, active));
  }

  Future<bool> moveTable(CafeTable table, int delta) {
    final int currentIndex = tables.indexOf(table);
    return _write(() => _tables.reorderTable(table.id, currentIndex + delta));
  }

  Future<bool> _write(Future<Object?> Function() operation) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      tables = await _tables.listTables();
      return true;
    } on Object catch (error) {
      errorMessage = _messageFor(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is DomainError) {
      return error.message;
    }
    return 'No se pudieron cargar las mesas. Intenta nuevamente.';
  }
}
