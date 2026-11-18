import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/transfer_request.dart';
import '../../domain/entities/transfer_result.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_remote_data_source.dart';

/// No automatic retry here: a retry is the user's choice, with the same key.
class TransferRepositoryImpl implements TransferRepository {
  const TransferRepositoryImpl(this._remote);

  final TransferRemoteDataSource _remote;

  @override
  Future<Result<TransferResult>> transfer(
    TransferRequest request, {
    required String idempotencyKey,
  }) => guard(
    () async => (await _remote.transfer(
      request,
      idempotencyKey: idempotencyKey,
    )).toEntity(),
  );
}
