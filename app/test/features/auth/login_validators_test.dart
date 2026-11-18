import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/features/auth/domain/validators/login_validators.dart';

// TST-01 / AUTH-02: login form validation.
void main() {
  group('validateEmail', () {
    test('empty or blank asks for an email', () {
      expect(validateEmail(''), 'Enter your email');
      expect(validateEmail('   '), 'Enter your email');
    });

    test('malformed addresses are rejected', () {
      for (final bad in [
        'demo',
        'demo@',
        '@jstack.co',
        'demo@jstack',
        'de mo@jstack.co',
      ]) {
        expect(validateEmail(bad), 'Enter a valid email address', reason: bad);
      }
    });

    test('a well-formed address passes, ignoring outer spaces', () {
      expect(validateEmail('demo@jstack.co'), isNull);
      expect(validateEmail('  demo@jstack.co  '), isNull);
    });
  });

  group('validatePassword', () {
    test('empty asks for a password', () {
      expect(validatePassword(''), 'Enter your password');
    });

    test('anything non-empty passes; the backend decides if it is right', () {
      expect(validatePassword('Demo@123'), isNull);
      expect(validatePassword(' '), isNull);
    });
  });
}
