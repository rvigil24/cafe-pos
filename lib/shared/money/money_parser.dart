import '../../domain/errors/domain_error.dart';

const int _maxSqliteInteger = 9223372036854775807;

int parsePriceCents(String input) {
  return _parseMoneyCents(
    input,
    emptyMessage: 'Ingresa un precio.',
    invalidMessage: 'Usa un número no negativo con máximo dos decimales.',
    tooLargeMessage: 'El precio es demasiado grande.',
    field: 'price',
  );
}

int parseReceivedCents(String input) {
  return _parseMoneyCents(
    input,
    emptyMessage: 'Ingresa el monto recibido.',
    invalidMessage: 'Usa un monto no negativo con máximo dos decimales.',
    tooLargeMessage: 'El monto recibido es demasiado grande.',
    field: 'received',
  );
}

int _parseMoneyCents(
  String input, {
  required String emptyMessage,
  required String invalidMessage,
  required String tooLargeMessage,
  required String field,
}) {
  final String value = input.trim();
  if (value.isEmpty) {
    throw ValidationError(emptyMessage, field: field);
  }
  if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(value)) {
    throw ValidationError(invalidMessage, field: field);
  }

  final List<String> parts = value.split('.');
  final String fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
  final int? cents = int.tryParse('${parts[0]}$fraction');
  if (cents == null || cents > _maxSqliteInteger) {
    throw ValidationError(tooLargeMessage, field: field);
  }
  return cents;
}

String formatPriceCents(int cents) {
  final int whole = cents ~/ 100;
  final String fraction = (cents % 100).toString().padLeft(2, '0');
  return '$whole.$fraction';
}
