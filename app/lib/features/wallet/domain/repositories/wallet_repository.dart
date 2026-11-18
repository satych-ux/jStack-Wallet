import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/wallet.dart';

abstract interface class WalletRepository {
  /// GET /users/profile: the name the dashboard greets (WAL-01).
  Future<Result<User>> getProfile();

  /// GET /wallet/balance (WAL-02).
  Future<Result<Wallet>> getWallet();
}
