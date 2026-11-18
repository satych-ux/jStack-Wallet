import 'package:flutter/foundation.dart';

/// A fault to apply to the next transfer request only.
enum TransferFault {
  /// Asks the backend to hold its answer 12 s, past the app's 10 s timeout:
  /// the transfer goes through but the app times out ("NOT CONFIRMED").
  slowServer,

  /// Sends the last successful transfer's Idempotency-Key with this new
  /// payload: the backend answers 409 IDEMPOTENCY_KEY_REUSED.
  reuseLastKey,

  /// Leaves the Idempotency-Key header out: the backend answers 400.
  dropKey,
}

/// What the debug panel has switched on. Read by [DebugInterceptor] on every
/// request; shown and changed by the panel.
///
/// Every option changes the real request sent to the backend, so the error
/// the app shows is the backend's own. The exception is [offline]: a phone
/// with no connection gets no answer at all, so that one fails locally.
class DebugSettings extends ChangeNotifier {
  /// Debug builds always; other builds only with
  /// `--dart-define=DEBUG_PANEL=true`. Release builds never show it.
  static const bool enabled = kDebugMode || bool.fromEnvironment('DEBUG_PANEL');

  /// How long the "slow server" option asks the backend to wait. Longer
  /// than the app's 10 s receive timeout.
  static const int slowServerMs = 12000;

  TransferFault? _nextTransfer;
  bool _offline = false;
  String? _lastSuccessfulKey;

  TransferFault? get nextTransfer => _nextTransfer;
  bool get offline => _offline;

  /// The Idempotency-Key of the last transfer that succeeded in this run,
  /// needed by [TransferFault.reuseLastKey].
  String? get lastSuccessfulKey => _lastSuccessfulKey;

  /// True when any option is armed, so the button can show it.
  bool get isActive => _nextTransfer != null || _offline;

  set nextTransfer(TransferFault? fault) {
    _nextTransfer = fault;
    notifyListeners();
  }

  set offline(bool value) {
    _offline = value;
    notifyListeners();
  }

  /// Returns the armed transfer fault and disarms it: it applies once.
  TransferFault? takeTransferFault() {
    final fault = _nextTransfer;
    if (fault != null) {
      _nextTransfer = null;
      notifyListeners();
    }
    return fault;
  }

  void recordSuccessfulKey(String key) {
    _lastSuccessfulKey = key;
    notifyListeners();
  }
}
