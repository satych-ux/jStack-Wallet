import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/error/failure.dart';
import 'package:j_stack_flutter_app/features/auth/presentation/login_error_message.dart';

void main() {
  test('wrong credentials, no connection and a timeout each get their own message', () {
    expect(loginErrorMessage(const UnauthorizedFailure()), 'Incorrect email or password.');
    expect(loginErrorMessage(const NetworkFailure()), contains('Could not reach the server'));
    expect(loginErrorMessage(const TimeoutFailure()), contains('took too long'));
  });

  test('every failure has a non-empty message that never mentions an exception', () {
    const failures = <Failure>[
      NetworkFailure(),
      TimeoutFailure(),
      UnauthorizedFailure(),
      ValidationFailure(),
      InsufficientBalanceFailure(),
      IdempotencyKeyReusedFailure(),
      NotFoundFailure(),
      ServerFailure(),
    ];
    for (final failure in failures) {
      final message = loginErrorMessage(failure);
      expect(message, isNotEmpty, reason: '$failure');
      expect(message, isNot(contains('Exception')), reason: '$failure');
    }
  });
}
