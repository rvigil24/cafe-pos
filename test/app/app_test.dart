import 'package:cafe_pos/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Material 3 bootstrap screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CafePosApp());

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );

    expect(app.theme?.useMaterial3, isTrue);
    expect(find.text('Cafe POS'), findsOneWidget);
    expect(find.text('Milestone 0 ready'), findsOneWidget);
    expect(find.byIcon(Icons.local_cafe_outlined), findsOneWidget);
  });

  testWidgets('shows a recoverable database initialization error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CafePosApp(
        catalogLoader: () => Future.error(StateError('database unavailable')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo abrir la información local.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
  });
}
