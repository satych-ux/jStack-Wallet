/// Every success from the backend is `{ "success": true, "data": ... }`.
/// Returns `data` as a JSON object, or throws [FormatException] when the body
/// is not that shape (repositories turn that into a ServerFailure).
Map<String, dynamic> dataObject(Object? body) {
  if (body is Map<String, dynamic> && body['success'] == true) {
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
  }
  throw const FormatException('Response is not { success: true, data: {...} }');
}

/// Same as [dataObject], for endpoints whose `data` is a JSON array.
List<dynamic> dataList(Object? body) {
  if (body is Map<String, dynamic> && body['success'] == true) {
    final data = body['data'];
    if (data is List<dynamic>) return data;
  }
  throw const FormatException('Response is not { success: true, data: [...] }');
}
