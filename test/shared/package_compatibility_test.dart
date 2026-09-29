import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:uuid/uuid.dart';

void main() {
  test('generates a valid UUID v4', () {
    final String id = const Uuid().v4();

    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('loads the America/El_Salvador timezone', () {
    timezone_data.initializeTimeZones();
    final timezone.Location location = timezone.getLocation(
      'America/El_Salvador',
    );
    final timezone.TZDateTime localDate = timezone.TZDateTime(
      location,
      2026,
      9,
      26,
      12,
    );

    expect(localDate.timeZoneOffset, const Duration(hours: -6));
  });
}
