import 'package:intl/intl.dart';

import '../../../../core/presentation/formatters.dart';
import '../../../../core/widgets/status_label.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_display.dart';

/// One transaction as the history screen receives it.
class HistoryEntry {
  const HistoryEntry({
    required this.reference,
    required this.name,
    required this.amount,
    required this.direction,
    required this.status,
    required this.createdAt,
  });

  factory HistoryEntry.fromTransaction(Transaction t) => HistoryEntry(
    reference: t.id,
    name: t.name,
    amount: Formatters.amount(t.amount),
    direction: txnDirection(t.type),
    status: statusKind(t.status),
    createdAt: t.createdAt.toLocal(),
  );

  final String reference;
  final String name;

  /// Unsigned and formatted, e.g. `1,500.00`.
  final String amount;
  final TxnDirection direction;
  final StatusKind status;

  /// Used to sort and to group by day.
  final DateTime createdAt;
}

enum HistoryFilter { all, credit, debit }

/// A day's header and its rows, ready to render.
class HistoryGroup {
  const HistoryGroup({required this.title, required this.rows});

  /// e.g. `20 OCTOBER 2026`.
  final String title;
  final List<TransactionRowData> rows;
}

final DateFormat _dayFormat = DateFormat('d MMMM y');

/// Everything the history list does to its data, in one pure function so
/// it is tested directly and never runs inside `build`:
/// filter by direction, search reference or name (case-insensitive,
/// TXN-02), sort newest first (TXN-01), group by calendar day.
List<HistoryGroup> groupHistory(
  List<HistoryEntry> entries, {
  String query = '',
  HistoryFilter filter = HistoryFilter.all,
}) {
  final needle = query.trim().toLowerCase();

  bool matches(HistoryEntry e) {
    final directionOk = switch (filter) {
      HistoryFilter.all => true,
      HistoryFilter.credit => e.direction == TxnDirection.credit,
      HistoryFilter.debit => e.direction == TxnDirection.debit,
    };
    return directionOk &&
        (needle.isEmpty ||
            e.reference.toLowerCase().contains(needle) ||
            e.name.toLowerCase().contains(needle));
  }

  final kept = entries.where(matches).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final groups = <HistoryGroup>[];
  for (final e in kept) {
    final title = _dayFormat.format(e.createdAt).toUpperCase();
    if (groups.isEmpty || groups.last.title != title) {
      groups.add(HistoryGroup(title: title, rows: []));
    }
    groups.last.rows.add(
      TransactionRowData(
        name: e.name,
        reference: e.reference,
        metaLabel: e.direction == TxnDirection.debit ? 'DEBIT' : 'CREDIT',
        amount: e.amount,
        direction: e.direction,
        status: e.status,
      ),
    );
  }
  return groups;
}
