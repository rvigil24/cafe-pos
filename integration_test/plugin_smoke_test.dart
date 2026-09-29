import 'dart:io';

import 'package:cafe_pos/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches and rolls back a SQLite transaction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CafePosApp());
    expect(find.text('Cafe POS'), findsOneWidget);

    final Directory temporaryDirectory = await getTemporaryDirectory();
    final String databasePath = path.join(
      temporaryDirectory.path,
      'cafe_pos_milestone_0.db',
    );
    await deleteDatabase(databasePath);
    final Database database = await openDatabase(databasePath);

    try {
      await expectLater(
        database.transaction<void>((Transaction transaction) async {
          await transaction.execute(
            'CREATE TABLE rollback_probe (id INTEGER PRIMARY KEY)',
          );
          throw StateError('Force rollback');
        }),
        throwsStateError,
      );

      final List<Map<String, Object?>> tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        <Object?>['rollback_probe'],
      );
      expect(tables, isEmpty);
    } finally {
      await database.close();
      await deleteDatabase(databasePath);
    }
  });
}
