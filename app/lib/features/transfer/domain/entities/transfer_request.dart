// TEMPORARY presentation scaffolding. Delete when the data slice lands.

/// What the user typed on Send money, sent to POST /transactions/transfer.
class TransferRequest {
  const TransferRequest({
    required this.beneficiaryName,
    required this.mobileNumber,
    required this.amount,
    this.remarks,
  });

  final String beneficiaryName;
  final String mobileNumber;
  final double amount;
  final String? remarks;
}
