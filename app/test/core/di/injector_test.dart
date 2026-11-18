import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/config/app_config.dart';
import 'package:j_stack_flutter_app/core/di/injector.dart';
import 'package:j_stack_flutter_app/core/network/auth_interceptor.dart';
import 'package:j_stack_flutter_app/core/network/session_expired_signal.dart';
import 'package:j_stack_flutter_app/core/network/token_store.dart';

import '../../helpers/fixtures.dart';


class _OneToken implements TokenStore {
  String? token = 'mock_access_token_123';

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async => token = null;
}

class _Always401 implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(
        jsonEncode(fixture('profile_401.json')),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => configureDependencies(config: const AppConfig(baseUrl: 'http://test/api/v1')));
  tearDown(() => getIt.reset());

  test('registers the config and the session-expired signal', () {
    expect(getIt<AppConfig>().baseUrl, 'http://test/api/v1');
    expect(getIt<SessionExpiredSignal>(), same(getIt<SessionExpiredSignal>()));
  });

  test('Dio is lazy: registering it needs no token store yet', () {
    expect(getIt.isRegistered<TokenStore>(), isFalse);
    expect(getIt.isRegistered<Dio>(), isTrue);
  });

  test('once a token store is registered, Dio resolves as one configured instance with the auth interceptor', () {
    getIt.registerSingleton<TokenStore>(_OneToken());

    final dio = getIt<Dio>();

    expect(dio, same(getIt<Dio>()));
    expect(dio.options.baseUrl, 'http://test/api/v1');
    expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
  });

  test('a 401 through the registered Dio clears the token and fires the registered signal', () async {
    final store = _OneToken();
    getIt.registerSingleton<TokenStore>(store);
    final dio = getIt<Dio>()..httpClientAdapter = _Always401();
    final fired = getIt<SessionExpiredSignal>().stream.first;

    await expectLater(dio.get<Object?>('/users/profile'), throwsA(isA<DioException>()));

    await expectLater(fired.timeout(const Duration(seconds: 1)), completes);
    expect(store.token, isNull);
  });
}
