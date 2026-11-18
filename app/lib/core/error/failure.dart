import 'package:equatable/equatable.dart';

/// Everything that can go wrong talking to the backend, as a closed set.
/// Repositories return these, never a `DioException`, and every screen shows
/// a message chosen by the failure's type, never a raw exception string.
sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => const [];
}

/// No connection: server down, no network, request cancelled.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Connected, but the server did not answer in time. The outcome of a
/// transfer is unknown, so the retry must reuse the same Idempotency-Key.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// 401: wrong credentials at login, or a missing/expired token elsewhere.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

/// 400. [fields] maps each bad request field to the backend's message; it is
/// empty when the problem was not a field (e.g. a missing Idempotency-Key).
final class ValidationFailure extends Failure {
  const ValidationFailure({this.fields = const {}});

  final Map<String, String> fields;

  @override
  List<Object?> get props => [fields];
}

/// 409 INSUFFICIENT_BALANCE: the wallet was not debited.
final class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure();
}

/// 409 IDEMPOTENCY_KEY_REUSED: the key was already used for a different
/// transfer. Should never happen in normal use; kept separate so it is never
/// mistaken for insufficient balance.
final class IdempotencyKeyReusedFailure extends Failure {
  const IdempotencyKeyReusedFailure();
}

/// 404, e.g. an unknown transaction id.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// 500 or any answer the app doesn't understand.
final class ServerFailure extends Failure {
  const ServerFailure();
}
