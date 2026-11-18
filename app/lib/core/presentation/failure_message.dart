import '../error/failure.dart';

/// What a screen section says when it couldn't load (WAL-06). Chosen by the
/// failure's type, never from an exception's text. A 401 never gets here:
/// the session ends and the app returns to login instead.
String sectionErrorMessage(Failure failure) => switch (failure) {
  NetworkFailure() => 'Could not reach the wallet. Check your connection and try again.',
  TimeoutFailure() => 'The wallet took too long to answer. Try again.',
  NotFoundFailure() => 'This could not be found.',
  UnauthorizedFailure() ||
  ValidationFailure() ||
  InsufficientBalanceFailure() ||
  IdempotencyKeyReusedFailure() ||
  ServerFailure() => 'Something went wrong. Try again.',
};
