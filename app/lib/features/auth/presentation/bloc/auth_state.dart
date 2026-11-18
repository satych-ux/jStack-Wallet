part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// No session: the router shows login.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// A login request is in flight (AUTH-03: the button shows loading).
final class AuthSubmitting extends AuthState {
  const AuthSubmitting();
}

/// The last login attempt failed; still signed out (AUTH-04, AUTH-08).
final class AuthLoginFailed extends AuthState {
  const AuthLoginFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Signed in: a token is stored. At startup this is assumed from a stored
/// token while `/users/profile` confirms it (AUTH-06).
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}
