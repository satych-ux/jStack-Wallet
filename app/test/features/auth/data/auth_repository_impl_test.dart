import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/error/failure.dart';
import 'package:j_stack_flutter_app/core/error/result.dart';
import 'package:j_stack_flutter_app/features/auth/domain/entities/user.dart';

import '../../../helpers/auth_stack.dart';
import '../../../helpers/fake_backend.dart';

const _login = 'POST /api/v1/auth/login';
const _profile = 'GET /api/v1/users/profile';
const _aditi = User(id: 'USR1001', name: 'Aditi Verma', email: 'demo@jstack.co');

void main() {
  group('login', () {
    test('stores the token in secure storage on success and returns the user', () async {
      final stack = AuthStack(backend: FakeBackend({_login: (status: 200, fixture: 'login_success.json')}));

      final result = await stack.repository.login(email: 'demo@jstack.co', password: 'Demo@123');

      expect(result, isA<Ok<User>>().having((r) => r.value, 'user', _aditi));
      expect(stack.storedToken, 'mock_access_token_123');
    });

    test('returns UnauthorizedFailure on 401 and stores nothing', () async {
      final stack = AuthStack(backend: FakeBackend({_login: (status: 401, fixture: 'login_401.json')}));

      final result = await stack.repository.login(email: 'demo@jstack.co', password: 'wrong');

      expect(result, isA<Err<User>>().having((r) => r.failure, 'failure', const UnauthorizedFailure()));
      expect(stack.storedToken, isNull);
    });

    test('a 400 is a ValidationFailure naming the fields, and stores nothing', () async {
      final stack = AuthStack(backend: FakeBackend({_login: (status: 400, fixture: 'login_400_validation.json')}));

      final result = await stack.repository.login(email: '', password: '');

      expect(
        (result as Err<User>).failure,
        const ValidationFailure(fields: {'email': 'Email is required', 'password': 'Password is required'}),
      );
      expect(stack.storedToken, isNull);
    });

    test('no connection is a NetworkFailure, and stores nothing', () async {
      final backend = FakeBackend()..failures[_login] = DioExceptionType.connectionError;
      final stack = AuthStack(backend: backend);

      final result = await stack.repository.login(email: 'demo@jstack.co', password: 'Demo@123');

      expect((result as Err<User>).failure, const NetworkFailure());
      expect(stack.storedToken, isNull);
    });

    test('a 200 with a body of the wrong shape is a ServerFailure, and stores nothing', () async {
      final stack = AuthStack(backend: FakeBackend({_login: (status: 200, fixture: 'profile.json')}));

      final result = await stack.repository.login(email: 'demo@jstack.co', password: 'Demo@123');

      expect((result as Err<User>).failure, const ServerFailure());
      expect(stack.storedToken, isNull);
    });

    test('login never sends a stored token', () async {
      final backend = FakeBackend({_login: (status: 200, fixture: 'login_success.json')});
      final stack = AuthStack(backend: backend, storedToken: 'stale');

      await stack.repository.login(email: 'demo@jstack.co', password: 'Demo@123');

      expect(backend.requests.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('restoreSession', () {
    test('no stored token: Ok(null), and no request is made', () async {
      final backend = FakeBackend();
      final stack = AuthStack(backend: backend);

      expect(await stack.repository.restoreSession(), isA<Ok<User?>>().having((r) => r.value, 'user', isNull));
      expect(backend.requests, isEmpty);
    });

    test('a stored token is checked with /users/profile; valid gives the user', () async {
      final backend = FakeBackend({_profile: (status: 200, fixture: 'profile.json')});
      final stack = AuthStack(backend: backend, storedToken: 'mock_access_token_123');

      final result = await stack.repository.restoreSession();

      expect(backend.calls, [_profile]);
      expect(backend.requests.single.headers['Authorization'], 'Bearer mock_access_token_123');
      expect(result, isA<Ok<User?>>().having((r) => r.value, 'user', _aditi));
      expect(stack.storedToken, 'mock_access_token_123');
    });

    test('a rejected token (401) is cleared and reported as UnauthorizedFailure', () async {
      final stack = AuthStack(
        backend: FakeBackend({_profile: (status: 401, fixture: 'profile_401.json')}),
        storedToken: 'expired',
      );

      final result = await stack.repository.restoreSession();

      expect((result as Err<User?>).failure, const UnauthorizedFailure());
      expect(stack.storedToken, isNull);
    });

    test('offline at startup keeps the token: nothing says it is invalid', () async {
      final backend = FakeBackend()..failures[_profile] = DioExceptionType.connectionError;
      final stack = AuthStack(backend: backend, storedToken: 'mock_access_token_123');

      final result = await stack.repository.restoreSession();

      expect((result as Err<User?>).failure, const NetworkFailure());
      expect(stack.storedToken, 'mock_access_token_123');
    });
  });

  test('logout clears the token, and is safe to repeat', () async {
    final stack = AuthStack(backend: FakeBackend(), storedToken: 'mock_access_token_123');

    await stack.repository.logout();
    await stack.repository.logout();

    expect(stack.storedToken, isNull);
  });
}
