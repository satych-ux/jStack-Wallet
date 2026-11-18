import '../../../core/error/failure.dart';

/// What the login screen says for each way a login can fail (AUTH-04,
/// AUTH-08). Chosen by type, never from an exception's text.
String loginErrorMessage(Failure failure) => switch (failure) {
  UnauthorizedFailure() => 'Incorrect email or password.',
  NetworkFailure() => 'Could not reach the server. Check your connection and try again.',
  TimeoutFailure() => 'The server took too long to answer. Try again.',
  ValidationFailure() => 'Enter a valid email and password.',
  ServerFailure() ||
  NotFoundFailure() ||
  InsufficientBalanceFailure() ||
  IdempotencyKeyReusedFailure() => 'Something went wrong. Try again.',
};
