import '../../domain/entities/transfer_request.dart';

/// The JSON body of POST /transactions/transfer. Remarks are left out when
/// empty; the backend treats absent and empty alike.
class TransferRequestModel {
  const TransferRequestModel(this.request);

  final TransferRequest request;

  Map<String, Object> toJson() => {
    'beneficiaryName': request.beneficiaryName,
    'mobileNumber': request.mobileNumber,
    'amount': request.amount,
    if (request.remarks case final remarks? when remarks.trim().isNotEmpty)
      'remarks': remarks,
  };
}
