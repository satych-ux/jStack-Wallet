import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'fixtures.dart';

/// A canned reply: an HTTP status and the captured fixture to send back.
typedef Reply = ({int status, String fixture});

/// Stands in for the network under a real `Dio`: answers each request with
/// a captured fixture, by "METHOD /path", and records what was sent. The
/// interceptors, timeouts config and JSON decoding all still run.
class FakeBackend implements HttpClientAdapter {
  FakeBackend([Map<String, Reply>? replies]) : replies = {...?replies};

  /// e.g. `{'POST /auth/login': (status: 200, fixture: 'login_success.json')}`.
  final Map<String, Reply> replies;

  /// Requests that should fail without a response, e.g. connectionError.
  final Map<String, DioExceptionType> failures = {};

  final List<RequestOptions> requests = [];

  List<String> get calls => [for (final r in requests) '${r.method} ${r.uri.path}'];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final key = '${options.method} ${options.uri.path}';
    final failure = failures[key];
    if (failure != null) throw DioException(requestOptions: options, type: failure);
    final reply = replies[key];
    if (reply == null) throw StateError('FakeBackend has no reply for $key');
    return ResponseBody.fromString(
      jsonEncode(fixture(reply.fixture)),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
