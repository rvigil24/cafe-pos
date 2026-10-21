import 'package:cafe_pos/application/use_cases/settings_use_cases.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  test('trims and persists the business name with a UTC timestamp', () async {
    final FakeSettingsRepository repository = FakeSettingsRepository();
    final SettingsUseCases useCases = SettingsUseCases(
      repository,
      clock: () => DateTime.parse('2026-10-20T12:00:00-06:00'),
    );

    await useCases.setBusinessName('  Café Centro  ');

    expect((await useCases.load()).businessName, 'Café Centro');
    expect(repository.lastUpdatedAt, DateTime.utc(2026, 10, 20, 18));
  });

  test('rejects empty and overly long business names', () async {
    final SettingsUseCases useCases = SettingsUseCases(
      FakeSettingsRepository(),
      clock: DateTime.now,
    );

    await expectLater(
      useCases.setBusinessName('   '),
      throwsA(isA<ValidationError>()),
    );
    await expectLater(
      useCases.setBusinessName('x' * 81),
      throwsA(isA<ValidationError>()),
    );
  });
}
