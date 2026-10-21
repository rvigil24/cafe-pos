import 'dart:typed_data';

class BackupSource {
  const BackupSource({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class BackupFileStorage {
  Future<Uri?> save({required String fileName, required Uint8List bytes});

  Future<BackupSource?> pick();
}
