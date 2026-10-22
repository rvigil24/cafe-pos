import 'package:cafe_pos/app/theme.dart';
import 'package:cafe_pos/shared/presentation/cafe_colors.dart';
import 'package:cafe_pos/shared/presentation/pos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operational state labels meet 4.5 to 1 contrast', () {
    for (final (Color foreground, Color background) in <(Color, Color)>[
      (Colors.white, CafeColors.terracotta),
      (CafeColors.terracotta, CafeColors.terracottaSoft),
      (CafeColors.sage, CafeColors.sageSoft),
      (CafeColors.amber, CafeColors.amberSoft),
      (CafeColors.danger, CafeColors.dangerSoft),
      (CafeColors.muted, CafeColors.ivory),
    ]) {
      final double first = foreground.computeLuminance();
      final double second = background.computeLuminance();
      final double lighter = first > second ? first : second;
      final double darker = first < second ? first : second;
      expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('working page exposes progress and disabled touch action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCafeTheme(),
        home: Scaffold(
          body: PosPage(
            title: 'Guardando',
            isWorking: true,
            actions: <Widget>[
              FilledButton(onPressed: null, child: const Text('Guardar')),
            ],
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final Finder action = find.widgetWithText(FilledButton, 'Guardar');
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
  });
}
