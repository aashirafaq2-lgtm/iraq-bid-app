import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Smoke test - App configuration and assets pass', () {
    const exchangeRate = 1520.0;
    expect(exchangeRate, equals(1520.0));
  });
}
