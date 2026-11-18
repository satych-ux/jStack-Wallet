import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/config/app_config.dart';
import 'package:j_stack_flutter_app/core/network/dio_client.dart';

class _Marker extends Interceptor {}

void main() {
  const config = AppConfig(baseUrl: 'http://10.0.2.2:3000/api/v1');

  test('uses the configured base URL and 10s connect and receive timeouts', () {
    final dio = createDio(config);

    expect(dio.options.baseUrl, 'http://10.0.2.2:3000/api/v1');
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 10));
  });

  test('sends and expects JSON', () {
    final dio = createDio(config);

    expect(dio.options.contentType, Headers.jsonContentType);
    expect(dio.options.responseType, ResponseType.json);
  });

  test('installs the given interceptors', () {
    final marker = _Marker();

    expect(createDio(config, interceptors: [marker]).interceptors, contains(marker));
  });

  test('an empty base URL fails fast, naming the --dart-define to set', () {
    expect(
      () => createDio(const AppConfig(baseUrl: '')),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('--dart-define=API_BASE_URL'), contains('10.0.2.2'), contains('localhost')),
        ),
      ),
    );
  });

  test('AppConfig defaults to 10s timeouts', () {
    expect(config.connectTimeout, const Duration(seconds: 10));
    expect(config.receiveTimeout, const Duration(seconds: 10));
  });

  test('AppConfig.fromEnvironment uses the API_BASE_URL define and 10s timeouts', () {
    // Passes with or without `--dart-define=API_BASE_URL=...` on `flutter test`.
    final config = AppConfig.fromEnvironment();

    expect(config.baseUrl, const String.fromEnvironment('API_BASE_URL'));
    expect(config.connectTimeout, const Duration(seconds: 10));
    expect(config.receiveTimeout, const Duration(seconds: 10));
  });
}
