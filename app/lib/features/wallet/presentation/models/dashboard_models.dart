/// Display-ready values for the dashboard, and the pure functions that
/// build them from domain objects. The screen only lays them out.
library;

import '../../../../core/presentation/formatters.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/models/transaction_display.dart';
import '../../domain/entities/wallet.dart';

class ProfileView {
  const ProfileView({required this.name, required this.initials});

  factory ProfileView.fromUser(User user) =>
      ProfileView(name: user.name, initials: Formatters.initials(user.name));

  final String name;

  /// e.g. `AV` for Aditi Verma.
  final String initials;
}

class BalanceView {
  const BalanceView({
    required this.balance,
    required this.walletId,
    required this.maskedAccount,
  });

  factory BalanceView.fromWallet(Wallet wallet) => BalanceView(
    balance: Formatters.rupees(wallet.availableBalance),
    walletId: wallet.walletId,
    maskedAccount: wallet.maskedAccountNumber,
  );

  /// Formatted with currency, e.g. `₹25,450.75`. From the backend, never
  /// computed in the app.
  final String balance;
  final String walletId;
  final String maskedAccount;
}

/// How many transactions the dashboard shows (WAL-04).
const int recentLimit = 5;

/// The latest [recentLimit] transactions as dashboard rows, in the order the
/// backend sent them (newest first).
List<TransactionRowData> recentRows(List<Transaction> transactions) => [
  for (final t in transactions.take(recentLimit)) transactionRow(t),
];

TransactionRowData transactionRow(Transaction t) => TransactionRowData(
  name: t.name,
  reference: t.id,
  metaLabel: Formatters.shortDate(t.createdAt),
  amount: Formatters.amount(t.amount),
  direction: txnDirection(t.type),
  status: statusKind(t.status),
);
