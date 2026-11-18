import 'package:dio/dio.dart';

import 'debug_settings.dart';

/// Applies the debug panel's options to outgoing requests. Installed only
/// when [DebugSettings.enabled]. Runs after the auth interceptor, so it sees
/// each request as it will really be sent.
class DebugInterceptor extends Interceptor {
  DebugInterceptor(this._settings);

  static const _keyHeader = 'Idempotency-Key';

  final DebugSettings _settings;

  bool _isTransfer(RequestOptions options) =>
      options.method == 'POST' &&
      options.uri.path.endsWith('/transactions/transfer');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_settings.offline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Offline (debug panel)',
        ),
      );
      return;
    }
    if (_isTransfer(options)) {
      switch (_settings.takeTransferFault()) {
        case TransferFault.slowServer:
          options.queryParameters['simulateLatencyMs'] =
              DebugSettings.slowServerMs;
        case TransferFault.reuseLastKey:
          final lastKey = _settings.lastSuccessfulKey;
          if (lastKey != null) options.headers[_keyHeader] = lastKey;
        case TransferFault.dropKey:
          options.headers.remove(_keyHeader);
        case null:
          break;
      }
    }
    handler.next(options);
  }

  /// Remembers each successful transfer's key, for "reuse the last key".
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = response.requestOptions.headers[_keyHeader];
    if (_isTransfer(response.requestOptions) &&
        response.statusCode == 200 &&
        key is String) {
      _settings.recordSuccessfulKey(key);
    }
    handler.next(response);
  }
}
