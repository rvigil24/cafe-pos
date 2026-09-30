import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/shared/money/money_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePriceCents', () {
    test('converts decimal text exactly to cents', () {
      expect(parsePriceCents('0'), 0);
      expect(parsePriceCents('2.5'), 250);
      expect(parsePriceCents(' 12.34 '), 1234);
    });

    test('rejects empty, negative, malformed, and over-precision values', () {
      for (final String value in <String>['', '-1', 'one', '1,25', '1.234']) {
        expect(() => parsePriceCents(value), throwsA(isA<ValidationError>()));
      }
    });

    test('rejects values outside the SQLite integer range', () {
      expect(
        () => parsePriceCents('92233720368547758.08'),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  test('formats cents without floating point arithmetic', () {
    expect(formatPriceCents(5), '0.05');
    expect(formatPriceCents(1234), '12.34');
  });
}
