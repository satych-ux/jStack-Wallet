import 'failure.dart';

/// What a repository returns: a value, or the [Failure] that stopped it.
/// Callers `switch` on it, so a failure can't be forgotten the way an
/// uncaught exception can.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
