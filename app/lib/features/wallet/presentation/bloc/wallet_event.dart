part of 'wallet_bloc.dart';

sealed class WalletEvent {
  const WalletEvent();
}

/// First load of all three sections.
final class WalletStarted extends WalletEvent {
  const WalletStarted();
}

/// Pull-to-refresh (WAL-05): balance and transactions again, plus the
/// profile if it had failed. [done] completes when the reload finishes, so
/// the refresh indicator knows when to stop.
final class WalletRefreshed extends WalletEvent {
  WalletRefreshed([Completer<void>? done]) : done = done ?? Completer<void>();

  final Completer<void> done;
}

final class WalletBalanceRetried extends WalletEvent {
  const WalletBalanceRetried();
}

final class WalletRecentRetried extends WalletEvent {
  const WalletRecentRetried();
}
