import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/transfer_result.dart';

part 'transfer_result_model.g.dart';

/// `data` of a successful transfer, as in transfer_success.json.
@JsonSerializable(createToJson: false)
class TransferResultModel {
  const TransferResultModel({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.availableBalance,
    required this.createdAt,
  });

  factory TransferResultModel.fromJson(Map<String, dynamic> json) =>
      _$TransferResultModelFromJson(json);

  final String transactionId;
  final String status;

  /// Read as `num`: whole rupees arrive as an int.
  @JsonKey(fromJson: _toDouble)
  final double amount;
  final String currency;
  @JsonKey(fromJson: _toDouble)
  final double availableBalance;
  final DateTime createdAt;

  TransferResult toEntity() => TransferResult(
    transactionId: transactionId,
    status: status,
    amount: amount,
    currency: currency,
    availableBalance: availableBalance,
    createdAt: createdAt,
  );
}

double _toDouble(Object? value) => (value! as num).toDouble();
