import 'package:intl/intl.dart';

import 'transfer_draft.dart';

final NumberFormat _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// Display-ready values for the confirmation screen. Whoever builds this
/// does the formatting (currency, `+91` prefix).
class ConfirmationView {
  const ConfirmationView({
    required this.amount,
    required this.beneficiaryName,
    required this.mobileNumber,
    this.remarks,
    this.fee = '₹0.00',
    this.balanceAfter,
  });

  /// Formats a validated draft for display. The amount is parsed only to
  /// print it with grouping and two decimals; no balance is involved.
  /// `balanceAfter` stays null (see its comment).
  factory ConfirmationView.fromDraft(TransferDraft draft) => ConfirmationView(
    amount: _rupees.format(double.parse(draft.amount)),
    beneficiaryName: draft.beneficiaryName,
    mobileNumber: '+91 ${draft.mobileNumber}',
    remarks: draft.remarks,
  );

  /// e.g. `₹1,500.00`.
  final String amount;
  final String beneficiaryName;

  /// e.g. `+91 9876543210`.
  final String mobileNumber;

  /// Null hides the row.
  final String? remarks;

  /// Transfers are free in this app.
  final String fee;

  /// Only ever a value the backend returned. The app must not compute
  /// `available - amount` (rule 1: the backend owns the balance). Null hides
  /// the row, which is the case until the backend offers a preview.
  final String? balanceAfter;
}
