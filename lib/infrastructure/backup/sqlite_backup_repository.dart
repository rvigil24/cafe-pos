import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/backup_result.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/backup_repository.dart';
import '../database/app_database.dart';
import 'backup_file_storage.dart';
import 'backup_validator.dart';

typedef DirectoryLoader = Future<Directory> Function();

class SqliteBackupRepository implements BackupRepository {
  SqliteBackupRepository(
    this._database,
    this._storage, {
    this.validator = const BackupValidator(),
    this.temporaryDirectory = getTemporaryDirectory,
    this.supportDirectory = getApplicationSupportDirectory,
    this.clock = DateTime.now,
  });

  final AppDatabase _database;
  final BackupFileStorage _storage;
  final BackupValidator validator;
  final DirectoryLoader temporaryDirectory;
  final DirectoryLoader supportDirectory;
  final DateTime Function() clock;

  @override
  Future<BackupExportResult?> exportBackup() async {
    File? snapshot;
    try {
      final Directory temporary = await temporaryDirectory();
      await temporary.create(recursive: true);
      final String fileName = 'cafe_pos_${_fileTimestamp()}.db';
      snapshot = File(path.join(temporary.path, fileName));
      await _database.maintain<void>((
        DatabaseMaintenanceSession session,
      ) async {
        await session.close();
        await File(session.path).copy(snapshot!.path);
        await validator.validateFile(snapshot!.path);
      });
      final Uint8List bytes = await snapshot.readAsBytes();
      final Uri? location = await _storage.save(
        fileName: fileName,
        bytes: bytes,
      );
      if (location == null) {
        return null;
      }
      return BackupExportResult(
        fileName: fileName,
        location: location.toString(),
      );
    } on DomainError {
      rethrow;
    } on Object {
      throw const BackupOperationError(
        'No se pudo exportar el respaldo. Intenta nuevamente.',
      );
    } finally {
      await _deleteIfPresent(snapshot);
    }
  }

  @override
  Future<BackupRestoreResult?> restoreBackup() async {
    File? candidate;
    try {
      final BackupSource? source = await _storage.pick();
      if (source == null) {
        return null;
      }
      final Directory temporary = await temporaryDirectory();
      await temporary.create(recursive: true);
      candidate = File(
        path.join(temporary.path, 'restore_candidate_${_fileTimestamp()}.db'),
      );
      await candidate.writeAsBytes(source.bytes, flush: true);
      await validator.validateFile(candidate.path);

      final String preventivePath = await _database.maintain<String>((
        DatabaseMaintenanceSession session,
      ) async {
        await session.close();
        final File live = File(session.path);
        final Directory backupDirectory = Directory(
          path.join((await supportDirectory()).path, 'backups'),
        );
        await backupDirectory.create(recursive: true);
        final File preventive = File(
          path.join(
            backupDirectory.path,
            'cafe_pos_pre_restore_${_fileTimestamp()}.db',
          ),
        );
        await live.copy(preventive.path);
        await validator.validateFile(
          preventive.path,
          requireCurrentVersion: true,
        );

        final File staged = File('${session.path}.restore');
        final File rollback = File('${session.path}.rollback');
        await _deleteIfPresent(staged);
        await _deleteIfPresent(rollback);
        await candidate!.copy(staged.path);
        await live.rename(rollback.path);
        try {
          await staged.rename(live.path);
          final database = await session.reopen();
          await validator.validateDatabase(
            database,
            requireCurrentVersion: true,
          );
          await _deleteIfPresent(rollback);
        } on Object {
          await session.close();
          await _deleteIfPresent(live);
          if (await rollback.exists()) {
            await rollback.rename(live.path);
          }
          await session.reopen();
          rethrow;
        } finally {
          await _deleteIfPresent(staged);
        }
        return preventive.path;
      });
      return BackupRestoreResult(
        sourceName: source.name,
        preventiveBackupPath: preventivePath,
      );
    } on DomainError {
      rethrow;
    } on Object {
      throw const BackupOperationError(
        'No se pudo restaurar el respaldo. Los datos anteriores se conservaron.',
      );
    } finally {
      await _deleteIfPresent(candidate);
    }
  }

  String _fileTimestamp() {
    return clock()
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp('[-:]'), '')
        .replaceAll('.', '');
  }

  Future<void> _deleteIfPresent(File? file) async {
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }
}
