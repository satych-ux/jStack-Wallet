import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_remote_data_source.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  const TransactionsRepositoryImpl(this._remote);

  final TransactionsRemoteDataSource _remote;

  /// Kept in the backend's order (newest first); never re-sorted here.
  @override
  Future<Result<List<Transaction>>> getTransactions() =>
      guard(() async => [for (final model in await _remote.list()) model.toEntity()]);

  @override
  Future<Result<Transaction>> getTransaction(String id) => guard(() async => (await _remote.details(id)).toEntity());
}
