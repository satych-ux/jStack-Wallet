// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../entities/transfer_request.dart';
import '../entities/transfer_result.dart';

abstract class TransferRepository {
  /// [idempotencyKey] is generated when the confirmation screen opens and
  /// reused on every retry of the same attempt.
  Future<TransferResult> transfer(
    TransferRequest request, {
    required String idempotencyKey,
  });
}
