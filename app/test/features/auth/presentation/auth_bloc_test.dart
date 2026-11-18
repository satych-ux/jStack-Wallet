import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/error/failure.dart';
import 'package:j_stack_flutter_app/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../helpers/auth_stack.dart';
import '../../../helpers/fake_backend.dart';

const _login = 'POST /api/v1/auth/login';
const _profile = 'GET /api/v1/users/profile';
const _balance = 'GET /api/v1/wallet/balance';

/// The real Dio stack answers a few event-loop turns later, not at once.
const _network = Duration(milliseconds: 100);

AuthBloc _bloc(AuthStack stack, {AuthState initial = const AuthUnauthenticated()}) =>
    AuthBloc(repository: stack.repository, sessionExpired: stack.signal, initialState: initial);

void main() {
  group('login', () {
    final stack = AuthStack(backend: FakeBackend({_login: (status: 200, fixture: 'login_success.json')}));
    blocTest<AuthBloc, AuthState>(
      'initial to submitting to authenticated, with the token stored',
      build: () => _bloc(stack),
      wait: _network,
      act: (bloc) => bloc.add(const AuthLoginSubmitted(email: 'demo@jstack.co', password: 'Demo@123')),
      expect: () => const [AuthSubmitting(), AuthAuthenticated()],
      verify: (_) => expect(stack.storedToken, 'mock_access_token_123'),
    );

    final rejected = AuthStack(backend: FakeBackend({_login: (status: 401, fixture: 'login_401.json')}));
    blocTest<AuthBloc, AuthState>(
      'initial to submitting to failure, with no token stored',
      build: () => _bloc(rejected),
      wait: _network,
      act: (bloc) => bloc.add(const AuthLoginSubmitted(email: 'demo@jstack.co', password: 'wrong')),
      expect: () => const [AuthSubmitting(), AuthLoginFailed(UnauthorizedFailure())],
      verify: (_) => expect(rejected.storedToken, isNull),
    );

    final offline = AuthStack(backend: FakeBackend()..failures[_login] = DioExceptionType.receiveTimeout);
    blocTest<AuthBloc, AuthState>(
      'a timeout is a failure the user can retry (AUTH-08)',
      build: () => _bloc(offline),
      wait: _network,
      act: (bloc) => bloc.add(const AuthLoginSubmitted(email: 'demo@jstack.co', password: 'Demo@123')),
      expect: () => const [AuthSubmitting(), AuthLoginFailed(TimeoutFailure())],
    );

    final backend = FakeBackend({_login: (status: 200, fixture: 'login_success.json')});
    blocTest<AuthBloc, AuthState>(
      'a double submit sends one request (droppable)',
      build: () => _bloc(AuthStack(backend: backend)),
      wait: _network,
      act: (bloc) => bloc
        ..add(const AuthLoginSubmitted(email: 'demo@jstack.co', password: 'Demo@123'))
        ..add(const AuthLoginSubmitted(email: 'demo@jstack.co', password: 'Demo@123')),
      expect: () => const [AuthSubmitting(), AuthAuthenticated()],
      verify: (_) => expect(backend.calls, [_login]),
    );
  });

  group('logout', () {
    final stack = AuthStack(backend: FakeBackend(), storedToken: 'mock_access_token_123');
    blocTest<AuthBloc, AuthState>(
      'clears storage and emits unauthenticated',
      build: () => _bloc(stack, initial: const AuthAuthenticated()),
      wait: _network,
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => const [AuthUnauthenticated()],
      verify: (_) => expect(stack.storedToken, isNull),
    );

    blocTest<AuthBloc, AuthState>(
      'is idempotent: twice emits once and does not throw',
      build: () => _bloc(AuthStack(backend: FakeBackend(), storedToken: 't'), initial: const AuthAuthenticated()),
      wait: _network,
      act: (bloc) => bloc
        ..add(const AuthLogoutRequested())
        ..add(const AuthLogoutRequested()),
      expect: () => const [AuthUnauthenticated()],
    );
  });

  group('startup (AUTH-06)', () {
    final valid = AuthStack(
      backend: FakeBackend({_profile: (status: 200, fixture: 'profile.json')}),
      storedToken: 'mock_access_token_123',
    );
    blocTest<AuthBloc, AuthState>(
      'a stored token is checked with /users/profile; valid stays authenticated',
      build: valid.startBloc,
      wait: _network,
      expect: () => const <AuthState>[],
      verify: (bloc) {
        expect(valid.backend.calls, [_profile]);
        expect(bloc.state, const AuthAuthenticated());
      },
    );

    final expired = AuthStack(
      backend: FakeBackend({_profile: (status: 401, fixture: 'profile_401.json')}),
      storedToken: 'expired',
    );
    blocTest<AuthBloc, AuthState>(
      'a stored token rejected with 401 is cleared and lands unauthenticated',
      build: expired.startBloc,
      wait: _network,
      expect: () => const [AuthUnauthenticated()],
      verify: (_) => expect(expired.storedToken, isNull),
    );

    final offline = AuthStack(
      backend: FakeBackend()..failures[_profile] = DioExceptionType.connectionError,
      storedToken: 'mock_access_token_123',
    );
    blocTest<AuthBloc, AuthState>(
      'offline at startup keeps the session (no emission, token kept)',
      build: offline.startBloc,
      wait: _network,
      expect: () => const <AuthState>[],
      verify: (bloc) {
        expect(bloc.state, const AuthAuthenticated());
        expect(offline.storedToken, 'mock_access_token_123');
      },
    );

    final none = AuthStack(backend: FakeBackend());
    blocTest<AuthBloc, AuthState>(
      'no stored token: stays unauthenticated and asks nothing',
      build: none.startBloc,
      wait: _network,
      expect: () => const <AuthState>[],
      verify: (_) => expect(none.backend.requests, isEmpty),
    );
  });

  group('session expiry', () {
    final stack = AuthStack(
      backend: FakeBackend({_balance: (status: 401, fixture: 'profile_401.json')}),
      storedToken: 'mock_access_token_123',
    );
    blocTest<AuthBloc, AuthState>(
      'a 401 from any later call drives the bloc to unauthenticated',
      build: () => _bloc(stack, initial: const AuthAuthenticated()),
      wait: _network,
      act: (_) async {
        await stack.dio.get<Object?>('/wallet/balance').then<void>((_) {}, onError: (Object _) {});
      },
      expect: () => const [AuthUnauthenticated()],
      verify: (_) => expect(stack.storedToken, isNull),
    );

    final signal = AuthStack(backend: FakeBackend());
    blocTest<AuthBloc, AuthState>(
      'repeated expiry signals move the user once',
      build: () => _bloc(signal, initial: const AuthAuthenticated()),
      wait: _network,
      act: (_) => signal.signal
        ..fire()
        ..fire()
        ..fire(),
      expect: () => const [AuthUnauthenticated()],
    );

    final early = AuthStack(backend: FakeBackend());
    blocTest<AuthBloc, AuthState>(
      'an expiry signal while signed out changes nothing',
      build: () => _bloc(early),
      wait: _network,
      act: (_) => early.signal.fire(),
      expect: () => const <AuthState>[],
    );
  });

  test('closing the bloc stops listening to the expiry signal', () async {
    final stack = AuthStack(backend: FakeBackend());
    final bloc = _bloc(stack, initial: const AuthAuthenticated());

    await bloc.close();
    stack.signal.fire();
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, const AuthAuthenticated());
  });
}
