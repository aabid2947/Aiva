// Smoke test. Full widget tests that mock AuthService/secure storage can be
// added later; for now we verify the auth model compiles and behaves.
import 'package:aiva/features/auth/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth status enum includes the expected states', () {
    expect(
      AuthStatus.values,
      containsAll(<AuthStatus>[
        AuthStatus.unknown,
        AuthStatus.authenticated,
        AuthStatus.unauthenticated,
      ]),
    );
  });
}
