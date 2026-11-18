// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../entities/transaction.dart';

abstract class TransactionsRepository {
  /// Newest first.
  Future<List<Transaction>> getTransactions();

  Future<Transaction> getTransaction(String id);
}
