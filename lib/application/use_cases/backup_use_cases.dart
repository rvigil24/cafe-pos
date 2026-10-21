import '../../domain/entities/backup_result.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupUseCases {
  const BackupUseCases(this._backups);

  final BackupRepository _backups;

  Future<BackupExportResult?> exportBackup() => _backups.exportBackup();

  Future<BackupRestoreResult?> restoreBackup() => _backups.restoreBackup();
}
