import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/wallet.dart';

part 'wallet_model.g.dart';

/// `data` of GET /wallet/balance, as in balance.json.
@JsonSerializable(createToJson: false)
class WalletModel {
  const WalletModel({
    required this.walletId,
    required this.currency,
    required this.availableBalance,
    required this.maskedAccountNumber,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);

  final String walletId;
  final String currency;

  /// JSON sends whole rupees as an int (`23950`) and others as a double
  /// (`25450.75`), so it is read as `num`, never `as double`.
  @JsonKey(fromJson: _toDouble)
  final double availableBalance;
  final String maskedAccountNumber;

  Wallet toEntity() => Wallet(
    walletId: walletId,
    currency: currency,
    availableBalance: availableBalance,
    maskedAccountNumber: maskedAccountNumber,
  );
}

double _toDouble(Object? value) => (value! as num).toDouble();
