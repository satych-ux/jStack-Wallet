import '../../../../core/widgets/status_label.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../domain/entities/transaction.dart';

/// How a transaction's type and status look on screen. Shared by the
/// dashboard, the history list and the details screen.
TxnDirection txnDirection(TransactionType type) => switch (type) {
  TransactionType.debit => TxnDirection.debit,
  TransactionType.credit => TxnDirection.credit,
};

StatusKind statusKind(TransactionStatus status) => switch (status) {
  TransactionStatus.success => StatusKind.success,
  TransactionStatus.pending => StatusKind.pending,
  TransactionStatus.failed => StatusKind.failed,
};
