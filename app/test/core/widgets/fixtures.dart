import 'package:j_stack_flutter_app/core/widgets/status_label.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';

const debitRow = TransactionRowData(
  name: 'Rahul Sharma',
  reference: 'TXN10001',
  metaLabel: '20 Oct',
  amount: '1,500.00',
  direction: TxnDirection.debit,
  status: StatusKind.success,
);

const creditRow = TransactionRowData(
  name: 'Amit Kumar',
  reference: 'TXN10002',
  metaLabel: '19 Oct',
  amount: '5,000.00',
  direction: TxnDirection.credit,
  status: StatusKind.success,
);
