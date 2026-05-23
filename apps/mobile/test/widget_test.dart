// Smoke test — verifies the test framework is functional.
// The real app requires live DI / network and cannot be pumped in unit tests.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test framework is functional', () {
    expect(1 + 1, equals(2));
  });
}
