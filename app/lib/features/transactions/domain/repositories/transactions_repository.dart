import '../../../../core/error/result.dart';
import '../entities/transaction.dart';

abstract interface class TransactionsRepository {
  /// GET /transactions, newest first as the backend sends it.
  Future<Result<List<Transaction>>> getTransactions();

  /// GET /transactions/:id. A 404 is a NotFoundFailure.
  Future<Result<Transaction>> getTransaction(String id);
}
