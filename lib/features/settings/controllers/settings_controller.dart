import 'package:flutter/foundation.dart';

import '../../../application/use_cases/backup_use_cases.dart';
import '../../../application/use_cases/settings_use_cases.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/backup_result.dart';
import '../../../domain/errors/domain_error.dart';

enum SettingsStatus { loading, ready, error }

class SettingsController extends ChangeNotifier {
  SettingsController(this._settings, this._backups);

  final SettingsUseCases _settings;
  final BackupUseCases _backups;

  SettingsStatus status = SettingsStatus.loading;
  AppSettings? settings;
  String? errorMessage;
  bool isWorking = false;

  Future<void> load() async {
    status = SettingsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      settings = await _settings.load();
      status = SettingsStatus.ready;
    } on Object catch (error) {
      status = SettingsStatus.error;
      errorMessage = _messageFor(error, 'No se pudo cargar la configuración.');
    }
    notifyListeners();
  }

  Future<bool> saveBusinessName(String value) async {
    return (await _run<bool>(() async {
          await _settings.setBusinessName(value);
          settings = await _settings.load();
          return true;
        })) ??
        false;
  }

  Future<BackupExportResult?> exportBackup() {
    return _run<BackupExportResult?>(_backups.exportBackup);
  }

  Future<BackupRestoreResult?> restoreBackup() {
    return _run<BackupRestoreResult?>(() async {
      final BackupRestoreResult? result = await _backups.restoreBackup();
      if (result != null) {
        settings = await _settings.load();
      }
      return result;
    });
  }

  Future<T?> _run<T>(Future<T> Function() operation) async {
    if (isWorking) {
      return null;
    }
    isWorking = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await operation();
    } on Object catch (error) {
      errorMessage = _messageFor(error, 'La operación no se pudo completar.');
      return null;
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error, String fallback) {
    return error is DomainError ? error.message : fallback;
  }
}
