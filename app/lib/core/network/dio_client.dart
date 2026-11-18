import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// The app's one `Dio`. JSON in and out, 10s connect and receive timeouts.
/// No retry interceptor: a transfer is retried only when the user asks, with
/// the same Idempotency-Key.
Dio createDio(AppConfig config, {List<Interceptor> interceptors = const []}) {
  if (config.baseUrl.isEmpty) {
    throw StateError(AppConfig.missingBaseUrlMessage);
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
