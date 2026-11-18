// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transactions_repository.dart';

/// Returns a fixed list so the dashboard, history and details screens can be
/// built before the backend is wired. Newest first, across two days, with
/// both types and all three statuses.
class FakeTransactionsRepository implements TransactionsRepository {
  const FakeTransactionsRepository();

  static final List<Transaction> sampleTransactions = [
    Transaction(
      id: 'TXN10006',
      type: TransactionType.debit,
      status: TransactionStatus.success,
      amount: 1500,
      currency: 'INR',
      name: 'Rahul Sharma',
      mobileNumber: '9876543210',
      createdAt: DateTime(2026, 10, 21, 14, 32),
      remarks: 'Dinner split',
    ),
    Transaction(
      id: 'TXN10005',
      type: TransactionType.credit,
      status: TransactionStatus.success,
      amount: 5000,
      currency: 'INR',
      name: 'Priya Nair',
      mobileNumber: '9123456780',
      createdAt: DateTime(2026, 10, 21, 9, 15),
    ),
    Transaction(
      id: 'TXN10004',
      type: TransactionType.debit,
      status: TransactionStatus.pending,
      amount: 799,
      currency: 'INR',
      name: 'Arjun Mehta',
      mobileNumber: '9988776655',
      createdAt: DateTime(2026, 10, 20, 19, 2),
      remarks: 'Concert ticket',
    ),
    Transaction(
      id: 'TXN10003',
      type: TransactionType.debit,
      status: TransactionStatus.failed,
      amount: 12000,
      currency: 'INR',
      name: 'Kavya Iyer',
      mobileNumber: '9011223344',
      createdAt: DateTime(2026, 10, 20, 16, 48),
    ),
    Transaction(
      id: 'TXN10002',
      type: TransactionType.credit,
      status: TransactionStatus.success,
      amount: 2250.5,
      currency: 'INR',
      name: 'Neha Gupta',
      mobileNumber: '9090909090',
      createdAt: DateTime(2026, 10, 20, 11, 20),
      remarks: 'Refund',
    ),
    Transaction(
      id: 'TXN10001',
      type: TransactionType.debit,
      status: TransactionStatus.success,
      amount: 320,
      currency: 'INR',
      name: 'Vikram Rao',
      mobileNumber: '9812345670',
      createdAt: DateTime(2026, 10, 20, 8, 5),
    ),
  ];

  @override
  Future<List<Transaction>> getTransactions() async => sampleTransactions;

  @override
  Future<Transaction> getTransaction(String id) async =>
      sampleTransactions.firstWhere((t) => t.id == id);
}
