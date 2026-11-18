// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferResultModel _$TransferResultModelFromJson(Map<String, dynamic> json) =>
    TransferResultModel(
      transactionId: json['transactionId'] as String,
      status: json['status'] as String,
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String,
      availableBalance: _toDouble(json['availableBalance']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
