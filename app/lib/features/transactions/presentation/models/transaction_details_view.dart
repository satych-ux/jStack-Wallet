import '../../../../core/widgets/status_label.dart';
import '../../../../core/widgets/transaction_row.dart';

/// Display-ready values for one transaction's details (TXN-07), from
/// GET /transactions/:id. Whoever builds this does the formatting.
class TransactionDetailsView {
  const TransactionDetailsView({
    required this.id,
    required this.direction,
    required this.status,
    required this.amount,
    required this.name,
    required this.mobileNumber,
    required this.dateTime,
    this.remarks,
  });

  final String id;
  final TxnDirection direction;
  final StatusKind status;

  /// Unsigned with currency, e.g. `₹1,500.00`. The screen adds `−` or `+`.
  final String amount;

  /// Beneficiary for a debit, sender for a credit.
  final String name;

  /// e.g. `+91 9876543210`.
  final String mobileNumber;

  /// e.g. `20 Oct 2026, 16:00`.
  final String dateTime;

  /// Null hides the row.
  final String? remarks;
}
