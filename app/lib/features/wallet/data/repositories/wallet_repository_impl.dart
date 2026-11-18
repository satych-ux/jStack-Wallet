import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Future<Result<User>> getProfile() => guard(() async => (await _remote.profile()).toEntity());

  @override
  Future<Result<Wallet>> getWallet() => guard(() async => (await _remote.balance()).toEntity());
}
