import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lets go_router listen to a bloc: notifies on every new state, so the
/// router re-runs its redirect when the user signs in or out.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
