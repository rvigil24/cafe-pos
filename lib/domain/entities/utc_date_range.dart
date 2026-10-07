class UtcDateRange {
  UtcDateRange({required DateTime start, required DateTime end})
    : start = start.toUtc(),
      end = end.toUtc() {
    if (!this.start.isBefore(this.end)) {
      throw ArgumentError('The start must be before the end.');
    }
  }

  final DateTime start;
  final DateTime end;
}
