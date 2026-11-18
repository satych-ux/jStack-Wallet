import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/session_expired_signal.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns "am I signed in?". The router redirects on it; the login screen
/// renders from it.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// [initialState] lets `main` start as signed in when a token is stored, so
  /// the dashboard opens at once while [AuthStarted] confirms the token.
  AuthBloc({
    required this._repository,
    required SessionExpiredSignal sessionExpired,
    AuthState initialState = const AuthUnauthenticated(),
  }) : super(initialState) {
    on<AuthStarted>(_onStarted);
    // A second tap while a login runs is dropped, not queued.
    on<AuthLoginSubmitted>(_onLoginSubmitted, transformer: droppable());
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    // Subscribed here, before any request can run: the signal is a
    // broadcast stream and drops events nobody is listening to.
    _expirySubscription = sessionExpired.stream.listen((_) => add(const AuthSessionExpired()));
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _expirySubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final AuthState? next = switch (await _repository.restoreSession()) {
      Ok(value: null) => const AuthUnauthenticated(),
      Ok() => const AuthAuthenticated(),
      Err(failure: UnauthorizedFailure()) => const AuthUnauthenticated(),
      // Offline or timed out: nothing says the token is bad, so keep the
      // session; the screens show their own errors with retry.
      Err() => null,
    };
    // Bloc lets a first emit through even when it equals the current state;
    // skipping it spares the router a pointless redirect at startup.
    if (next != null && next != state) emit(next);
  }

  Future<void> _onLoginSubmitted(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthSubmitting());
    switch (await _repository.login(email: event.email, password: event.password)) {
      case Ok():
        emit(const AuthAuthenticated());
      case Err(:final failure):
        emit(AuthLoginFailed(failure));
    }
  }

  /// Safe to repeat: clearing an absent token is fine, and emitting the
  /// state the bloc is already in is a no-op.
  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  /// The interceptor has already cleared the token. Only a signed-in user is
  /// moved; repeats (several 401s) change nothing.
  void _onSessionExpired(AuthSessionExpired event, Emitter<AuthState> emit) {
    if (state is AuthAuthenticated) emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() async {
    await _expirySubscription.cancel();
    return super.close();
  }
}
