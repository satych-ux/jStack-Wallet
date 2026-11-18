// TEMPORARY presentation scaffolding. Delete when the data slice lands.

/// The wallet summary, as returned by GET /wallet/balance.
/// The balance is whatever the backend says; the app never computes it.
class Wallet {
  const Wallet({
    required this.walletId,
    required this.currency,
    required this.availableBalance,
    required this.maskedAccountNumber,
  });

  final String walletId;
  final String currency;
  final double availableBalance;
  final String maskedAccountNumber;
}
