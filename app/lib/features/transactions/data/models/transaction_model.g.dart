// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      type: $enumDecode(
        _$TransactionTypeEnumMap,
        json['type'],
        unknownValue: TransactionType.debit,
      ),
      status: $enumDecode(
        _$TransactionStatusEnumMap,
        json['status'],
        unknownValue: TransactionStatus.pending,
      ),
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String,
      counterpartyName: json['counterpartyName'] as String,
      mobileNumber: json['mobileNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      remarks: json['remarks'] as String?,
    );

const _$TransactionTypeEnumMap = {
  TransactionType.debit: 'DEBIT',
  TransactionType.credit: 'CREDIT',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.success: 'SUCCESS',
  TransactionStatus.pending: 'PENDING',
  TransactionStatus.failed: 'FAILED',
};
