import 'package:equatable/equatable.dart';

/// The wallet summary from GET /wallet/balance. The balance is whatever the
/// backend says; the app never computes it.
class Wallet extends Equatable {
  const Wallet({
    required this.walletId,
    required this.currency,
    required this.availableBalance,
    required this.maskedAccountNumber,
  });

  final String walletId;
  final String currency;
  final double availableBalance;
  final String maskedAccountNumber;

  @override
  List<Object?> get props => [walletId, currency, availableBalance, maskedAccountNumber];
}
