import 'package:equatable/equatable.dart';

/// What POST /transactions/transfer sends. [amount] is the number the user
/// typed, already validated to at most 2 decimals; the app never changes it.
class TransferRequest extends Equatable {
  const TransferRequest({
    required this.beneficiaryName,
    required this.mobileNumber,
    required this.amount,
    this.remarks,
  });

  final String beneficiaryName;
  final String mobileNumber;
  final num amount;
  final String? remarks;

  @override
  List<Object?> get props => [beneficiaryName, mobileNumber, amount, remarks];
}
