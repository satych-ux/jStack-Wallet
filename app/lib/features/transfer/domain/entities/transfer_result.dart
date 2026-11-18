import 'package:equatable/equatable.dart';

/// A successful transfer, as the backend reported it. [availableBalance] is
/// the server's new balance: shown as is, never computed in the app.
class TransferResult extends Equatable {
  const TransferResult({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.availableBalance,
    required this.createdAt,
  });

  final String transactionId;
  final String status;
  final double amount;
  final String currency;
  final double availableBalance;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    transactionId,
    status,
    amount,
    currency,
    availableBalance,
    createdAt,
  ];
}
