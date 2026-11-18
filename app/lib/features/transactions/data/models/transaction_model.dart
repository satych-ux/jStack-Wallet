import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/transaction.dart';

part 'transaction_model.g.dart';

/// One transaction as in transactions.json and transaction_details.json.
@JsonSerializable(createToJson: false)
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.counterpartyName,
    required this.mobileNumber,
    required this.createdAt,
    this.remarks,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

  final String id;

  /// An unknown value reads as a debit: it never shows money as arriving.
  @JsonKey(unknownEnumValue: TransactionType.debit)
  final TransactionType type;

  /// An unknown value reads as pending: neither a success nor a failure is
  /// claimed that the backend didn't make.
  @JsonKey(unknownEnumValue: TransactionStatus.pending)
  final TransactionStatus status;

  /// Read as `num`: whole rupees arrive as an int.
  @JsonKey(fromJson: _toDouble)
  final double amount;
  final String currency;
  final String counterpartyName;
  final String mobileNumber;
  final String? remarks;

  /// ISO-8601 in UTC from the backend.
  final DateTime createdAt;

  Transaction toEntity() => Transaction(
    id: id,
    type: type,
    status: status,
    amount: amount,
    currency: currency,
    name: counterpartyName,
    mobileNumber: mobileNumber,
    createdAt: createdAt,
    remarks: remarks,
  );
}

double _toDouble(Object? value) => (value! as num).toDouble();
