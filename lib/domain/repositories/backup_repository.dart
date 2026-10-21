import '../entities/backup_result.dart';

abstract interface class BackupRepository {
  Future<BackupExportResult?> exportBackup();

  Future<BackupRestoreResult?> restoreBackup();
}
