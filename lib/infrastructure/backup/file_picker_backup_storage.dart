import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'backup_file_storage.dart';

class FilePickerBackupStorage implements BackupFileStorage {
  const FilePickerBackupStorage();

  @override
  Future<BackupSource?> pick() async {
    final PlatformFile? file = await FilePicker.pickFile(
      dialogTitle: 'Seleccionar respaldo de Cafe POS',
      type: FileType.custom,
      allowedExtensions: const <String>['db'],
    );
    if (file == null) {
      return null;
    }
    return BackupSource(name: file.name, bytes: await file.readAsBytes());
  }

  @override
  Future<Uri?> save({required String fileName, required Uint8List bytes}) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/vnd.sqlite3',
      dialogTitle: 'Guardar respaldo de Cafe POS',
    );
  }
}
