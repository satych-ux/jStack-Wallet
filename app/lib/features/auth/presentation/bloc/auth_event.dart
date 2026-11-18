part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// App start: check the stored token, if any (AUTH-06).
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// The backend rejected the token on some request (sent by the interceptor
/// through [SessionExpiredSignal]).
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
