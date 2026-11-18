// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletModel _$WalletModelFromJson(Map<String, dynamic> json) => WalletModel(
  walletId: json['walletId'] as String,
  currency: json['currency'] as String,
  availableBalance: _toDouble(json['availableBalance']),
  maskedAccountNumber: json['maskedAccountNumber'] as String,
);
