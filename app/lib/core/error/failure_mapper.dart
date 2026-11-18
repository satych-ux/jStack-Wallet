import 'package:dio/dio.dart';

import 'api_error.dart';
import 'failure.dart';

/// Turns anything Dio throws into a [Failure]. The one place that knows HTTP;
/// repositories call it and hand the result up.
Failure mapDioException(DioException exception) {
  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(),
    DioExceptionType.badResponse => mapErrorResponse(
      exception.response?.statusCode,
      exception.response?.data,
    ),
    // No usable answer arrived: refused, offline, cancelled, TLS, other.
    DioExceptionType.connectionError ||
    DioExceptionType.cancel ||
    DioExceptionType.badCertificate ||
    DioExceptionType.unknown => const NetworkFailure(),
  };
}

/// Maps a non-2xx answer by its status code, and for 409 by the backend's
/// error code (SPEC.md section 9). Anything unexpected is a [ServerFailure].
Failure mapErrorResponse(int? statusCode, Object? body) {
  final error = ApiError.tryParse(body);
  return switch (statusCode) {
    400 => ValidationFailure(fields: error?.fields ?? const {}),
    401 => const UnauthorizedFailure(),
    404 => const NotFoundFailure(),
    409 when error?.code == 'INSUFFICIENT_BALANCE' => const InsufficientBalanceFailure(),
    409 when error?.code == 'IDEMPOTENCY_KEY_REUSED' => const IdempotencyKeyReusedFailure(),
    _ => const ServerFailure(),
  };
}
