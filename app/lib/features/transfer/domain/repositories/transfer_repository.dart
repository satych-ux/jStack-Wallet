import '../../../../core/error/result.dart';
import '../entities/transfer_request.dart';
import '../entities/transfer_result.dart';

abstract interface class TransferRepository {
  /// Sends one transfer attempt. Retrying the same attempt must pass the
  /// same [idempotencyKey]; the backend then returns the original result
  /// instead of deducting twice.
  Future<Result<TransferResult>> transfer(
    TransferRequest request, {
    required String idempotencyKey,
  });
}
