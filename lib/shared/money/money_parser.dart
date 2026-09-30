import '../../domain/errors/domain_error.dart';

const int _maxSqliteInteger = 9223372036854775807;

int parsePriceCents(String input) {
  final String value = input.trim();
  if (value.isEmpty) {
    throw const ValidationError('Ingresa un precio.', field: 'price');
  }
  if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(value)) {
    throw const ValidationError(
      'Usa un número no negativo con máximo dos decimales.',
      field: 'price',
    );
  }

  final List<String> parts = value.split('.');
  final String fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
  final int? cents = int.tryParse('${parts[0]}$fraction');
  if (cents == null || cents > _maxSqliteInteger) {
    throw const ValidationError(
      'El precio es demasiado grande.',
      field: 'price',
    );
  }
  return cents;
}

String formatPriceCents(int cents) {
  final int whole = cents ~/ 100;
  final String fraction = (cents % 100).toString().padLeft(2, '0');
  return '$whole.$fraction';
}
