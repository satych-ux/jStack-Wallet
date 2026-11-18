/// What the user entered on Send money, validated and trimmed, on its way
/// to the confirmation screen. Values stay as the user typed them; turning
/// the amount into a number for the request is the data layer's job.
class TransferDraft {
  const TransferDraft({
    required this.amount,
    required this.beneficiaryName,
    required this.mobileNumber,
    this.remarks,
  });

  /// e.g. `1500.50`.
  final String amount;
  final String beneficiaryName;

  /// Ten digits, no country code.
  final String mobileNumber;

  /// Null when the user left it empty.
  final String? remarks;
}
