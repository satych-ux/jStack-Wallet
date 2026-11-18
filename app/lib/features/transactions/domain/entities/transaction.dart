import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

/// JSON values are the backend's upper-case names (`DEBIT`, `CREDIT`).
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TransactionType { debit, credit }

/// JSON values are `SUCCESS`, `PENDING`, `FAILED`.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TransactionStatus { success, pending, failed }

/// One row of GET /transactions, or the body of GET /transactions/:id.
/// [id] is also the reference shown to the user (e.g. TXN10001).
class Transaction extends Equatable {
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

  @override
  List<Object?> get props => [id, type, status, amount, currency, name, mobileNumber, createdAt, remarks];
}
