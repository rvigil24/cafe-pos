import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

final tz.Location _cafeLocation = tz.getLocation('America/El_Salvador');

String formatCafeTime(DateTime value) {
  return DateFormat('h:mm a').format(tz.TZDateTime.from(value, _cafeLocation));
}

String formatOpenDuration(DateTime createdAt, DateTime now) {
  final Duration elapsed = now.toUtc().difference(createdAt.toUtc());
  if (elapsed.inMinutes < 1) {
    return 'ahora';
  }
  if (elapsed.inHours < 1) {
    return '${elapsed.inMinutes} min';
  }
  final int minutes = elapsed.inMinutes.remainder(60);
  return '${elapsed.inHours} h ${minutes.toString().padLeft(2, '0')} min';
}
