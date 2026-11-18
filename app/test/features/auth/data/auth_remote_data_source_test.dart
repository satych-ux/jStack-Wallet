import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../../helpers/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late AuthRemoteDataSource remote;

  setUp(() {
    backend = FakeBackend({
      'POST /api/v1/auth/login': (status: 200, fixture: 'login_success.json'),
      'GET /api/v1/users/profile': (status: 200, fixture: 'profile.json'),
    });
    remote = AuthRemoteDataSource(Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = backend);
  });

  test('login POSTs the email and password to /auth/login and parses the response', () async {
    final response = await remote.login(email: 'demo@jstack.co', password: 'Demo@123');

    expect(backend.calls, ['POST /api/v1/auth/login']);
    expect(backend.requests.single.data, {'email': 'demo@jstack.co', 'password': 'Demo@123'});
    expect(response.accessToken, 'mock_access_token_123');
  });

  test('profile GETs /users/profile and parses the user', () async {
    final user = await remote.profile();

    expect(backend.calls, ['GET /api/v1/users/profile']);
    expect(user.email, 'demo@jstack.co');
  });

  test('a 401 surfaces as a DioException for the repository to map', () async {
    backend.replies['POST /api/v1/auth/login'] = (status: 401, fixture: 'login_401.json');

    await expectLater(
      remote.login(email: 'demo@jstack.co', password: 'x'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );
  });
}
