// TEMPORARY presentation scaffolding. Delete when the data slice lands.

enum TransactionType { debit, credit }

enum TransactionStatus { success, pending, failed }

/// One row of GET /transactions, or the body of GET /transactions/:id.
/// [id] is the reference shown to the user (e.g. TXN10001).
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.name,
    required this.mobileNumber,
    required this.createdAt,
    this.remarks,
  });

  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String currency;

  /// Beneficiary for a debit, sender for a credit.
  final String name;
  final String mobileNumber;
  final DateTime createdAt;
  final String? remarks;
}
