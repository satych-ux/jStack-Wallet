import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// The app's one `Dio`. JSON in and out, 10s connect and receive timeouts.
/// No retry interceptor: a transfer is retried only when the user asks, with
/// the same Idempotency-Key.
Dio createDio(AppConfig config, {List<Interceptor> interceptors = const []}) {
  if (config.baseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is not set. Run with --dart-define=API_BASE_URL=<url>, e.g. '
      'http://10.0.2.2:3000/api/v1 (Android emulator), '
      'http://<your-computer-LAN-IP>:3000/api/v1 (physical device), '
      'http://localhost:3000/api/v1 (iOS simulator).',
    );
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.addAll(interceptors);
  return dio;
}
