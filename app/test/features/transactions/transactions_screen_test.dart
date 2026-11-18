import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/presentation/section.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';
import 'package:j_stack_flutter_app/core/widgets/empty_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/error_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/filter_pill.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/transaction_row_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/status_label.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/models/history_view.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/screens/transactions_screen.dart';

HistoryEntry entry(
  String reference,
  String name,
  DateTime at,
  TxnDirection direction,
) => HistoryEntry(
  reference: reference,
  name: name,
  amount: '100.00',
  direction: direction,
  status: StatusKind.success,
  createdAt: at,
);

// Out of order on purpose; the screen must sort.
final entries = [
  entry(
    'TXN10003',
    'Priya Nair',
    DateTime(2026, 10, 19, 9),
    TxnDirection.debit,
  ),
  entry(
    'TXN10001',
    'Rahul Sharma',
    DateTime(2026, 10, 20, 16),
    TxnDirection.debit,
  ),
  entry(
    'TXN10004',
    'Neha Verma',
    DateTime(2026, 10, 18, 9),
    TxnDirection.credit,
  ),
  entry(
    'TXN10002',
    'Amit Kumar',
    DateTime(2026, 10, 20, 9),
    TxnDirection.credit,
  ),
];

class Calls {
  final opened = <String>[];
  int retry = 0;
}

Future<Calls> pumpHistory(
  WidgetTester tester, {
  Section<List<HistoryEntry>>? transactions,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calls = Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: TransactionsScreen(
        transactions: transactions ?? SectionLoaded(entries),
        onBack: () {},
        onOpen: calls.opened.add,
        onRetry: () => calls.retry++,
      ),
    ),
  );
  return calls;
}

/// Row names, top to bottom.
List<String> visibleNames(WidgetTester tester) {
  final rows = tester.widgetList<TransactionRow>(find.byType(TransactionRow));
  final names = [for (final r in rows) r.data.name];
  names.sort(
    (a, b) => tester
        .getTopLeft(find.text(a))
        .dy
        .compareTo(tester.getTopLeft(find.text(b)).dy),
  );
  return names;
}

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> pill(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilterPill, label));
  await tester.pump();
}

void main() {
  testWidgets('rows render newest first', (tester) async {
    await pumpHistory(tester);

    expect(visibleNames(tester), [
      'Rahul Sharma',
      'Amit Kumar',
      'Priya Nair',
      'Neha Verma',
    ]);
  });

  testWidgets('rows are grouped under date headers', (tester) async {
    await pumpHistory(tester);

    for (final header in [
      '20 OCTOBER 2026',
      '19 OCTOBER 2026',
      '18 OCTOBER 2026',
    ]) {
      expect(find.text(header), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.text('19 OCTOBER 2026')).dy,
      greaterThan(tester.getTopLeft(find.text('Amit Kumar')).dy),
    );
  });

  testWidgets('typing a reference filters to matching rows', (tester) async {
    await pumpHistory(tester);
    await search(tester, 'TXN10003');

    expect(visibleNames(tester), ['Priya Nair']);
  });

  testWidgets('typing a name filters to matching rows', (tester) async {
    await pumpHistory(tester);
    await search(tester, 'Neha');

    expect(visibleNames(tester), ['Neha Verma']);
  });

  testWidgets('search is case-insensitive', (tester) async {
    await pumpHistory(tester);
    await search(tester, 'aMiT');

    expect(visibleNames(tester), ['Amit Kumar']);
  });

  testWidgets('Credit, Debit and All pills filter and restore', (tester) async {
    await pumpHistory(tester);

    await pill(tester, 'Credit');
    expect(visibleNames(tester), ['Amit Kumar', 'Neha Verma']);

    await pill(tester, 'Debit');
    expect(visibleNames(tester), ['Rahul Sharma', 'Priya Nair']);

    await pill(tester, 'All');
    expect(visibleNames(tester), hasLength(4));
  });

  testWidgets('filters and search combine', (tester) async {
    await pumpHistory(tester);
    await pill(tester, 'Debit');
    await search(tester, 'r');

    expect(visibleNames(tester), ['Rahul Sharma', 'Priya Nair']);

    await search(tester, 'amit');
    expect(visibleNames(tester), isEmpty);
  });

  testWidgets('no matches shows the no-results copy, not the empty copy', (
    tester,
  ) async {
    await pumpHistory(tester);
    await search(tester, 'nobody');

    expect(find.text('No matching transactions'), findsOneWidget);
    expect(find.text('No transactions yet'), findsNothing);
  });

  testWidgets('an empty source list shows the empty state', (tester) async {
    await pumpHistory(tester, transactions: const SectionLoaded([]));

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('loading shows six row shimmers', (tester) async {
    await pumpHistory(tester, transactions: const SectionLoading());

    expect(find.byType(TransactionRowShimmer), findsNWidgets(6));
    expect(find.byType(TransactionRow), findsNothing);
  });

  testWidgets('error shows ErrorStateView and Retry fires', (tester) async {
    final calls = await pumpHistory(
      tester,
      transactions: const SectionFailed('Check the backend is running.'),
    );

    expect(find.byType(ErrorStateView), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(calls.retry, 1);
  });

  testWidgets('search and pills stay usable while the list shimmers', (
    tester,
  ) async {
    await pumpHistory(tester, transactions: const SectionLoading());

    await search(tester, 'rahul');
    await pill(tester, 'Credit');

    expect(find.text('rahul'), findsOneWidget);
    final credit = tester.widget<FilterPill>(
      find.widgetWithText(FilterPill, 'Credit'),
    );
    expect(credit.selected, isTrue);
    expect(find.byType(TransactionRowShimmer), findsNWidgets(6));
  });

  testWidgets('tapping a row fires with that row\'s id', (tester) async {
    final calls = await pumpHistory(tester);

    await tester.tap(find.text('Priya Nair'));

    expect(calls.opened, ['TXN10003']);
  });

  testWidgets('new data from the caller re-applies the current search', (
    tester,
  ) async {
    await pumpHistory(tester);
    await search(tester, 'neha');

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: TransactionsScreen(
          transactions: SectionLoaded([
            ...entries,
            entry(
              'TXN10009',
              'Neha Iyer',
              DateTime(2026, 10, 21),
              TxnDirection.debit,
            ),
          ]),
          onBack: () {},
          onOpen: (_) {},
          onRetry: () {},
        ),
      ),
    );

    expect(visibleNames(tester), ['Neha Iyer', 'Neha Verma']);
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    testWidgets('no overflow at ${size.width}x${size.height}', (tester) async {
      await pumpHistory(tester, size: size);

      expect(tester.takeException(), isNull);
    });
  }
}
