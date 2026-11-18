// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Returns a fixed wallet so the dashboard can be built before the backend
/// is wired.
class FakeWalletRepository implements WalletRepository {
  const FakeWalletRepository();

  static const Wallet sampleWallet = Wallet(
    walletId: 'WAL-7F3K-2291',
    currency: 'INR',
    availableBalance: 24850.75,
    maskedAccountNumber: 'XXXX XXXX 4821',
  );

  @override
  Future<Wallet> getWallet() async => sampleWallet;
}
