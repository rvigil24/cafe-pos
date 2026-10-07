import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/utc_date_range.dart';
import '../../domain/errors/domain_error.dart';

enum ReportPeriod { today, yesterday, thisWeek, thisMonth, custom }

class CafeCalendar {
  CafeCalendar(this.location);

  final tz.Location location;

  UtcDateRange reportRange(
    ReportPeriod period,
    DateTime now, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final tz.TZDateTime localNow = tz.TZDateTime.from(now, location);
    final tz.TZDateTime today = _day(localNow);
    return switch (period) {
      ReportPeriod.today => _range(today, _nextDay(today)),
      ReportPeriod.yesterday => _range(_dayWithOffset(today, -1), today),
      ReportPeriod.thisWeek => _weekRange(today),
      ReportPeriod.thisMonth => _range(
        tz.TZDateTime(location, today.year, today.month),
        tz.TZDateTime(location, today.year, today.month + 1),
      ),
      ReportPeriod.custom => inclusiveDateRange(customStart, customEnd),
    };
  }

  UtcDateRange inclusiveDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      throw const ValidationError(
        'Selecciona la fecha inicial y final.',
        field: 'dateRange',
      );
    }
    final tz.TZDateTime localStart = tz.TZDateTime(
      location,
      start.year,
      start.month,
      start.day,
    );
    final tz.TZDateTime localEnd = tz.TZDateTime(
      location,
      end.year,
      end.month,
      end.day,
    );
    if (localEnd.isBefore(localStart)) {
      throw const ValidationError(
        'La fecha final no puede ser anterior a la inicial.',
        field: 'dateRange',
      );
    }
    return _range(localStart, _nextDay(localEnd));
  }

  UtcDateRange _range(tz.TZDateTime start, tz.TZDateTime end) {
    return UtcDateRange(start: start.toUtc(), end: end.toUtc());
  }

  tz.TZDateTime _day(tz.TZDateTime value) {
    return tz.TZDateTime(location, value.year, value.month, value.day);
  }

  tz.TZDateTime _dayWithOffset(tz.TZDateTime day, int days) {
    return tz.TZDateTime(location, day.year, day.month, day.day + days);
  }

  UtcDateRange _weekRange(tz.TZDateTime today) {
    final tz.TZDateTime start = _dayWithOffset(
      today,
      -(today.weekday - DateTime.monday),
    );
    return _range(start, _dayWithOffset(start, 7));
  }

  tz.TZDateTime _nextDay(tz.TZDateTime day) => _dayWithOffset(day, 1);
}
