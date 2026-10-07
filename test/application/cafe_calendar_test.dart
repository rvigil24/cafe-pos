import 'package:cafe_pos/application/services/cafe_calendar.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late CafeCalendar calendar;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    calendar = CafeCalendar(tz.getLocation('America/El_Salvador'));
  });

  test('builds today and yesterday as half-open UTC ranges', () {
    final DateTime now = DateTime.utc(2026, 10, 6, 18, 30);

    final today = calendar.reportRange(ReportPeriod.today, now);
    final yesterday = calendar.reportRange(ReportPeriod.yesterday, now);

    expect(today.start, DateTime.utc(2026, 10, 6, 6));
    expect(today.end, DateTime.utc(2026, 10, 7, 6));
    expect(yesterday.start, DateTime.utc(2026, 10, 5, 6));
    expect(yesterday.end, DateTime.utc(2026, 10, 6, 6));
  });

  test('week starts Monday and month spans the full calendar period', () {
    final DateTime now = DateTime.utc(2026, 10, 6, 18, 30);

    final week = calendar.reportRange(ReportPeriod.thisWeek, now);
    final month = calendar.reportRange(ReportPeriod.thisMonth, now);

    expect(week.start, DateTime.utc(2026, 10, 5, 6));
    expect(week.end, DateTime.utc(2026, 10, 12, 6));
    expect(month.start, DateTime.utc(2026, 10, 1, 6));
    expect(month.end, DateTime.utc(2026, 11, 1, 6));
  });

  test('custom range includes the complete selected end date', () {
    final range = calendar.inclusiveDateRange(
      DateTime(2026, 9, 30),
      DateTime(2026, 10, 2),
    );

    expect(range.start, DateTime.utc(2026, 9, 30, 6));
    expect(range.end, DateTime.utc(2026, 10, 3, 6));
  });

  test('rejects a reversed or incomplete custom range', () {
    expect(
      () => calendar.inclusiveDateRange(
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 1),
      ),
      throwsA(isA<ValidationError>()),
    );
    expect(
      () => calendar.inclusiveDateRange(DateTime(2026, 10, 2), null),
      throwsA(isA<ValidationError>()),
    );
  });
}
