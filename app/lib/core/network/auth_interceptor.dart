import 'package:dio/dio.dart';

import 'token_store.dart';

/// Adds `Authorization: Bearer <token>` to every request that needs it, and
/// ends the session once when the backend rejects that token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._tokenStore, required this._onSessionExpired});

  static const _header = 'Authorization';

  /// Endpoints that never get the token. Login especially: a stale stored
  /// token on a wrong-password 401 must not look like an expired session.
  static const _publicPaths = ['/auth/login', '/health'];

  final TokenStore _tokenStore;
  final void Function() _onSessionExpired;

  /// True while one 401 is being handled, so parallel 401s end the session
  /// once instead of once each. Set before the first `await`, which Dart
  /// can't interleave with another request's handler.
  bool _ending = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isPublic = _publicPaths.any(options.uri.path.endsWith);
    final token = isPublic ? null : await _tokenStore.read();
    if (token != null && token.isNotEmpty) {
      options.headers[_header] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Only a 401 on a request that carried the *current* token means "signed
  /// out". A 401 without a token is a wrong password at login; a 401 for an
  /// older token (the user signed in again since) is stale and ignored.
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final sent = err.requestOptions.headers[_header];
    if (err.response?.statusCode == 401 && sent != null && !_ending) {
      _ending = true;
      try {
        final current = await _tokenStore.read();
        if (current != null && sent == 'Bearer $current') {
          try {
            await _tokenStore.clear();
          } catch (_) {
            // Sign out anyway: the user must not stay on screens that fail.
          }
          _onSessionExpired();
        }
      } finally {
        _ending = false;
      }
    }
    handler.next(err);
  }
}
