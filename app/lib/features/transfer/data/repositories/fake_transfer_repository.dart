// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../../domain/entities/transfer_request.dart';
import '../../domain/entities/transfer_result.dart';
import '../../domain/repositories/transfer_repository.dart';

/// Always "succeeds" with a fixed result so the result screen can be built
/// before the backend is wired. It ignores the request on purpose: it does
/// not compute a balance.
class FakeTransferRepository implements TransferRepository {
  const FakeTransferRepository();

  static const TransferResult sampleResult = TransferResult(
    transactionId: 'TXN10006',
    status: 'SUCCESS',
    amount: 1500,
    currency: 'INR',
    availableBalance: 23350.75,
  );

  @override
  Future<TransferResult> transfer(
    TransferRequest request, {
    required String idempotencyKey,
  }) async => sampleResult;
}
