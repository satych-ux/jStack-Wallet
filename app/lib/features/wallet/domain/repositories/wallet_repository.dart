// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<Wallet> getWallet();
}
