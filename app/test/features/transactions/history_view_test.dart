import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/widgets/status_label.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/models/history_view.dart';

HistoryEntry entry(
  String reference,
  String name,
  DateTime at, {
  TxnDirection direction = TxnDirection.debit,
}) => HistoryEntry(
  reference: reference,
  name: name,
  amount: '100.00',
  direction: direction,
  status: StatusKind.success,
  createdAt: at,
);

// Deliberately out of order.
final entries = [
  entry('TXN1', 'Rahul Sharma', DateTime(2026, 10, 19, 9)),
  entry(
    'TXN3',
    'Amit Kumar',
    DateTime(2026, 10, 20, 18),
    direction: TxnDirection.credit,
  ),
  entry('TXN2', 'Priya Nair', DateTime(2026, 10, 20, 8)),
  entry(
    'TXN4',
    'Neha Verma',
    DateTime(2026, 10, 18, 12),
    direction: TxnDirection.credit,
  ),
];

List<String> refs(List<HistoryGroup> groups) => [
  for (final g in groups)
    for (final r in g.rows) r.reference,
];

void main() {
  test('sorts newest first and groups by calendar day', () {
    final groups = groupHistory(entries);

    expect(refs(groups), ['TXN3', 'TXN2', 'TXN1', 'TXN4']);
    expect(groups.map((g) => g.title), [
      '20 OCTOBER 2026',
      '19 OCTOBER 2026',
      '18 OCTOBER 2026',
    ]);
  });

  test('rows show the type as their second meta span', () {
    final rows = groupHistory(entries).first.rows;

    expect(rows.map((r) => r.metaLabel), ['CREDIT', 'DEBIT']);
  });

  test('search matches reference or name, ignoring case and spaces', () {
    expect(refs(groupHistory(entries, query: 'txn3')), ['TXN3']);
    expect(refs(groupHistory(entries, query: '  PRIYA ')), ['TXN2']);
    expect(refs(groupHistory(entries, query: 'a')), [
      'TXN3',
      'TXN2',
      'TXN1',
      'TXN4',
    ]);
  });

  test('the direction filter keeps only that direction', () {
    expect(refs(groupHistory(entries, filter: HistoryFilter.credit)), [
      'TXN3',
      'TXN4',
    ]);
    expect(refs(groupHistory(entries, filter: HistoryFilter.debit)), [
      'TXN2',
      'TXN1',
    ]);
  });

  test('search and filter combine', () {
    expect(
      refs(groupHistory(entries, query: 'r', filter: HistoryFilter.credit)),
      ['TXN3', 'TXN4'],
    );
    expect(
      refs(groupHistory(entries, query: 'rahul', filter: HistoryFilter.credit)),
      isEmpty,
    );
  });

  test('empty input gives no groups', () {
    expect(groupHistory(const []), isEmpty);
  });
}
