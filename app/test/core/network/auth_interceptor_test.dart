import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/network/auth_interceptor.dart';
import 'package:j_stack_flutter_app/core/network/token_store.dart';

import '../../helpers/fixtures.dart';

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore([this.token]);

  String? token;
  int clears = 0;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async {
    clears++;
    token = null;
  }
}

/// Answers every request with [status] and [body], and records what was sent.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.status = 200, this.body = const {'success': true, 'data': {}}});

  final int status;
  final Object body;
  final List<RequestOptions> sent = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    sent.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _FakeAdapter adapter, List<String> expiries}) _build(
  _MemoryTokenStore store, {
  int status = 200,
  Object? body,
}) {
  final adapter = body == null ? _FakeAdapter(status: status) : _FakeAdapter(status: status, body: body);
  final expiries = <String>[];
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(AuthInterceptor(tokenStore: store, onSessionExpired: () => expiries.add('expired')));
  return (dio: dio, adapter: adapter, expiries: expiries);
}

void main() {
  test('adds Authorization: Bearer <token> when a token is stored', () async {
    final h = _build(_MemoryTokenStore('mock_access_token_123'));

    await h.dio.get<Object?>('/wallet/balance');

    expect(h.adapter.sent.single.headers['Authorization'], 'Bearer mock_access_token_123');
  });

  test('omits the header when no token is stored', () async {
    final h = _build(_MemoryTokenStore());

    await h.dio.post<Object?>('/auth/login', data: {'email': 'demo@jstack.co'});

    expect(h.adapter.sent.single.headers.containsKey('Authorization'), isFalse);
  });

  test('omits the header for an empty token', () async {
    final h = _build(_MemoryTokenStore(''));

    await h.dio.get<Object?>('/wallet/balance');

    expect(h.adapter.sent.single.headers.containsKey('Authorization'), isFalse);
  });

  test('reads the token on every request, so a new login is picked up', () async {
    final store = _MemoryTokenStore();
    final h = _build(store);

    await h.dio.get<Object?>('/health');
    store.token = 'mock_access_token_123';
    await h.dio.get<Object?>('/wallet/balance');

    expect(h.adapter.sent[0].headers.containsKey('Authorization'), isFalse);
    expect(h.adapter.sent[1].headers['Authorization'], 'Bearer mock_access_token_123');
  });

  test('a 401 on a request that carried a token clears it and signals expiry', () async {
    final store = _MemoryTokenStore('mock_access_token_123');
    final h = _build(store, status: 401, body: fixture('profile_401.json'));

    await expectLater(h.dio.get<Object?>('/wallet/balance'), throwsA(isA<DioException>()));

    expect(store.clears, 1);
    expect(store.token, isNull);
    expect(h.expiries, ['expired']);
  });

  test('a 401 without a token (wrong password at login) clears nothing and signals nothing', () async {
    final store = _MemoryTokenStore();
    final h = _build(store, status: 401, body: fixture('login_401.json'));

    await expectLater(
      h.dio.post<Object?>('/auth/login', data: {'email': 'demo@jstack.co', 'password': 'x'}),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );

    expect(store.clears, 0);
    expect(h.expiries, isEmpty);
  });

  test('other errors (e.g. 409) leave the session alone', () async {
    final store = _MemoryTokenStore('mock_access_token_123');
    final h = _build(store, status: 409, body: fixture('transfer_409_insufficient.json'));

    await expectLater(h.dio.post<Object?>('/transactions/transfer'), throwsA(isA<DioException>()));

    expect(store.clears, 0);
    expect(store.token, 'mock_access_token_123');
    expect(h.expiries, isEmpty);
  });

  test('the error still reaches the caller after a 401 is handled', () async {
    final h = _build(_MemoryTokenStore('t'), status: 401, body: fixture('profile_401.json'));

    await expectLater(
      h.dio.get<Object?>('/users/profile'),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.badResponse)),
    );
  });

  test('login never carries a stored token, so a wrong password with a stale token signs nobody out', () async {
    final store = _MemoryTokenStore('stale_token');
    final h = _build(store, status: 401, body: fixture('login_401.json'));

    await expectLater(
      h.dio.post<Object?>('/auth/login', data: {'email': 'demo@jstack.co', 'password': 'wrong'}),
      throwsA(isA<DioException>()),
    );

    expect(h.adapter.sent.single.headers.containsKey('Authorization'), isFalse);
    expect(store.clears, 0);
    expect(store.token, 'stale_token');
    expect(h.expiries, isEmpty);
  });

  test('health is public too: no token attached', () async {
    final h = _build(_MemoryTokenStore('mock_access_token_123'));

    await h.dio.get<Object?>('/health');

    expect(h.adapter.sent.single.headers.containsKey('Authorization'), isFalse);
  });

  test('several 401s at once end the session once', () async {
    // Reads take time, like secure storage, and the fake server answers all
    // three requests together, so the three 401s are handled at once.
    final store = _SlowTokenStore('mock_access_token_123');
    final adapter = _GatedAdapter(waitFor: 3, status: 401, body: fixture('profile_401.json'));
    final expiries = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(tokenStore: store, onSessionExpired: () => expiries.add('expired')));

    await Future.wait([
      for (final path in ['/users/profile', '/wallet/balance', '/transactions'])
        dio.get<Object?>(path).then<void>((_) {}, onError: (Object _) {}),
    ]);

    expect(adapter.sent, hasLength(3));
    expect(store.clears, 1);
    expect(expiries, ['expired']);
  });

  test('a late 401 for an old token does not clear a newer one', () async {
    // The 401 is for "old"; by the time it is handled the user signed in again.
    final store = _MemoryTokenStore('old');
    final adapter = _FakeAdapter(status: 401, body: fixture('profile_401.json'));
    final expiries = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        InterceptorsWrapper(
          // Runs after the request was sent with "old": simulate a re-login.
          onError: (e, handler) {
            store.token = 'new';
            handler.next(e);
          },
        ),
      )
      ..interceptors.add(AuthInterceptor(tokenStore: store, onSessionExpired: () => expiries.add('expired')));
    // Error interceptors run in the order added: the re-login wrapper first,
    // then AuthInterceptor, which now finds "new" stored.

    await expectLater(dio.get<Object?>('/wallet/balance'), throwsA(isA<DioException>()));

    expect(adapter.sent.single.headers['Authorization'], 'Bearer old');
    expect(store.token, 'new');
    expect(store.clears, 0);
    expect(expiries, isEmpty);
  });

  test('a later 401 after signing in again with the same token still ends the session', () async {
    final store = _MemoryTokenStore('mock_access_token_123');
    final h = _build(store, status: 401, body: fixture('profile_401.json'));

    await expectLater(h.dio.get<Object?>('/wallet/balance'), throwsA(isA<DioException>()));
    store.token = 'mock_access_token_123'; // signed in again; the mock token never changes
    await expectLater(h.dio.get<Object?>('/wallet/balance'), throwsA(isA<DioException>()));

    expect(store.clears, 2);
    expect(h.expiries, ['expired', 'expired']);
  });

  test('if clearing the token fails, the session still ends and the 401 still reaches the caller', () async {
    final store = _FailingClearStore('mock_access_token_123');
    final h = _build(store, status: 401, body: fixture('profile_401.json'));

    await expectLater(
      h.dio.get<Object?>('/wallet/balance'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );

    expect(h.expiries, ['expired']);
  });
}

class _FailingClearStore extends _MemoryTokenStore {
  _FailingClearStore(super.token);

  @override
  Future<void> clear() async => throw Exception('keychain locked');
}

/// Like secure storage: reading and clearing take a moment, so a second
/// read can still see the token while the first clear is in progress.
class _SlowTokenStore extends _MemoryTokenStore {
  _SlowTokenStore(super.token);

  @override
  Future<String?> read() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return token;
  }

  @override
  Future<void> clear() async {
    clears++;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    token = null;
  }
}

/// Holds every reply until [waitFor] requests have arrived, then answers them
/// all at once, so their error handling overlaps.
class _GatedAdapter extends _FakeAdapter {
  _GatedAdapter({required this.waitFor, required super.status, required super.body});

  final int waitFor;
  final _allArrived = Completer<void>();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final reply = super.fetch(options, requestStream, cancelFuture);
    if (sent.length == waitFor) _allArrived.complete();
    await _allArrived.future;
    return reply;
  }
}
