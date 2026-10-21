class BackupExportResult {
  const BackupExportResult({required this.fileName, required this.location});

  final String fileName;
  final String location;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.sourceName,
    required this.preventiveBackupPath,
  });

  final String sourceName;
  final String preventiveBackupPath;
}
