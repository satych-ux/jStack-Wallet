import 'dart:async';

/// Fires when the backend rejects a request that carried a token (401): the
/// session is over. The auth feature listens and signs the user out.
class SessionExpiredSignal {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void fire() => _controller.add(null);

  Future<void> dispose() => _controller.close();
}
