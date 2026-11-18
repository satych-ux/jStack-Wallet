// TEMPORARY presentation scaffolding. Delete when the data slice lands.

/// The backend's answer to a successful transfer (SPEC API-08).
/// [availableBalance] is the server's new balance, not a local calculation.
class TransferResult {
  const TransferResult({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.availableBalance,
  });

  final String transactionId;
  final String status;
  final double amount;
  final String currency;
  final double availableBalance;
}
