/// The backend's error body: `{ "success": false, "error": { code, message,
/// fields? } }`. `fields` is present only on 400 VALIDATION_ERROR.
class ApiError {
  const ApiError({required this.code, required this.message, this.fields = const {}});

  /// Parses a decoded response body, or returns null when it is not the
  /// error shape (no body, HTML from a proxy, a different JSON).
  static ApiError? tryParse(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final error = body['error'];
    if (error is! Map<String, dynamic>) return null;
    final code = error['code'];
    final message = error['message'];
    if (code is! String || message is! String) return null;

    final rawFields = error['fields'];
    final fields = <String, String>{
      if (rawFields is Map<String, dynamic>)
        for (final MapEntry(:key, :value) in rawFields.entries)
          if (value is String) key: value,
    };
    return ApiError(code: code, message: message, fields: fields);
  }

  /// e.g. `INSUFFICIENT_BALANCE`.
  final String code;
  final String message;

  /// Request field name → message, e.g. `{mobileNumber: Mobile number must be exactly 10 digits}`.
  final Map<String, String> fields;
}
