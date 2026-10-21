import 'package:cafe_pos/application/use_cases/backup_use_cases.dart';
import 'package:cafe_pos/application/use_cases/settings_use_cases.dart';
import 'package:cafe_pos/application/use_cases/table_use_cases.dart';
import 'package:cafe_pos/domain/entities/backup_result.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/features/settings/controllers/settings_controller.dart';
import 'package:cafe_pos/features/settings/pages/settings_page.dart';
import 'package:cafe_pos/features/tables/controllers/table_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('edits the business name and completes backup actions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final FakeSettingsRepository settings = FakeSettingsRepository();
    final FakeBackupRepository backups = FakeBackupRepository()
      ..exportResult = const BackupExportResult(
        fileName: 'cafe_pos.db',
        location: 'memory:///cafe_pos.db',
      )
      ..restoreResult = const BackupRestoreResult(
        sourceName: 'cafe_pos.db',
        preventiveBackupPath: '/private/preventive.db',
      );
    final SettingsController controller = SettingsController(
      SettingsUseCases(settings, clock: DateTime.now),
      BackupUseCases(backups),
    );
    final TableController tables = TableController(
      TableUseCases(
        tables: FakeTableRepository(),
        ids: FixedIds(),
        clock: DateTime.now,
      ),
    );
    addTearDown(controller.dispose);
    addTearDown(tables.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(controller: controller, tableController: tables),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cafetería'), findsOneWidget);
    await tester.tap(find.byTooltip('Editar nombre del negocio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Café Centro');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Café Centro'), findsOneWidget);
    expect(find.text('Nombre del negocio guardado.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.text('Exportar respaldo'));
    await tester.pumpAndSettle();
    expect(find.text('Respaldo cafe_pos.db exportado.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.text('Restaurar respaldo'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Los datos actuales serán reemplazados por el respaldo elegido. Antes del cambio se creará una copia preventiva.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Elegir respaldo'));
    await tester.pumpAndSettle();
    expect(find.text('Respaldo cafe_pos.db restaurado.'), findsOneWidget);
  });

  testWidgets('shows a recoverable backup error', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final FakeBackupRepository backups = FakeBackupRepository()
      ..error = const BackupValidationError('El respaldo está dañado.');
    final SettingsController controller = SettingsController(
      SettingsUseCases(FakeSettingsRepository(), clock: DateTime.now),
      BackupUseCases(backups),
    );
    final TableController tables = TableController(
      TableUseCases(
        tables: FakeTableRepository(),
        ids: FixedIds(),
        clock: DateTime.now,
      ),
    );
    addTearDown(controller.dispose);
    addTearDown(tables.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(controller: controller, tableController: tables),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exportar respaldo'));
    await tester.pumpAndSettle();
    expect(find.text('El respaldo está dañado.'), findsOneWidget);
    expect(find.text('Exportar respaldo'), findsOneWidget);
  });

  testWidgets('remains usable on a short landscape viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final SettingsController controller = SettingsController(
      SettingsUseCases(FakeSettingsRepository(), clock: DateTime.now),
      BackupUseCases(FakeBackupRepository()),
    );
    final TableController tables = TableController(
      TableUseCases(
        tables: FakeTableRepository(),
        ids: FixedIds(),
        clock: DateTime.now,
      ),
    );
    addTearDown(controller.dispose);
    addTearDown(tables.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(controller: controller, tableController: tables),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Editar nombre del negocio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Exportar respaldo'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Exportar respaldo'), findsOneWidget);
  });
}
