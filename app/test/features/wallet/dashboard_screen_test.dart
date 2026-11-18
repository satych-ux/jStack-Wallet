import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/presentation/section.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';
import 'package:j_stack_flutter_app/core/widgets/balance_panel.dart';
import 'package:j_stack_flutter_app/core/widgets/empty_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/error_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/quick_action_card.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/balance_panel_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/transaction_row_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/status_label.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';
import 'package:j_stack_flutter_app/features/wallet/presentation/models/dashboard_models.dart';
import 'package:j_stack_flutter_app/features/wallet/presentation/screens/dashboard_screen.dart';

// Deliberately unusual values, so a match proves they came from the model.
const profile = SectionLoaded(
  ProfileView(name: 'Zed Q Tester', initials: 'ZQ'),
);
const balance = SectionLoaded(
  BalanceView(
    balance: '₹98,765.43',
    walletId: 'WALLET-TEST-42',
    maskedAccount: 'XXXX XXXX 0042',
  ),
);

List<TransactionRowData> rows(int count) => List.generate(
  count,
  (i) => TransactionRowData(
    name: 'Person $i',
    reference: 'TXN2000$i',
    metaLabel: '1$i Oct',
    amount: '${i + 1}00.00',
    direction: i.isEven ? TxnDirection.debit : TxnDirection.credit,
    status: StatusKind.success,
  ),
);

/// Callback counters, so each test can check which one fired.
class Taps {
  int send = 0, history = 0, seeAll = 0, retryBalance = 0, retryList = 0;
  int refresh = 0;
  final opened = <String>[];
  Completer<void> refreshDone = Completer<void>();
}

Future<Taps> pumpDashboard(
  WidgetTester tester, {
  Section<ProfileView> profile = profile,
  Section<BalanceView> balance = balance,
  Section<List<TransactionRowData>>? recent,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taps = Taps();
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: DashboardScreen.fromSections(
        profile: profile,
        balance: balance,
        recent: recent ?? SectionLoaded(rows(5)),
        onRefresh: () {
          taps.refresh++;
          return taps.refreshDone.future;
        },
        onSendMoney: () => taps.send++,
        onHistory: () => taps.history++,
        onSeeAll: () => taps.seeAll++,
        onTransactionTap: taps.opened.add,
        onRetryBalance: () => taps.retryBalance++,
        onRetryTransactions: () => taps.retryList++,
      ),
    ),
  );
  return taps;
}

void main() {
  testWidgets('renders greeting, user name and avatar initials', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('Zed Q Tester'), findsOneWidget);
    expect(find.text('ZQ'), findsOneWidget);
  });

  testWidgets('balance, wallet id and account come from the model', (
    tester,
  ) async {
    await pumpDashboard(tester);

    final panel = tester.widget<BalancePanel>(find.byType(BalancePanel));
    expect(panel.balance, '₹98,765.43');
    expect(panel.walletId, 'WALLET-TEST-42');
    expect(panel.maskedAccount, 'XXXX XXXX 0042');
    expect(find.text('₹98,765.43'), findsOneWidget);
  });

  testWidgets('shows at most five transaction rows', (tester) async {
    await pumpDashboard(tester, recent: SectionLoaded(rows(8)));

    expect(find.byType(TransactionRow), findsNWidgets(5));
  });

  testWidgets('Add money is disabled and shows SOON', (tester) async {
    await pumpDashboard(tester);

    final addMoney = tester.widget<QuickActionCard>(
      find.widgetWithText(QuickActionCard, 'Add money'),
    );
    expect(addMoney.isComingSoon, isTrue);
    expect(find.text('SOON'), findsOneWidget);
  });

  testWidgets('Send money, History and See all fire their callbacks', (
    tester,
  ) async {
    final taps = await pumpDashboard(tester);

    await tester.tap(find.text('Send money'));
    await tester.tap(find.text('History'));
    await tester.tap(find.text('See all'));

    expect((taps.send, taps.history, taps.seeAll), (1, 1, 1));
  });

  testWidgets('tapping a row opens it by reference', (tester) async {
    final taps = await pumpDashboard(tester);

    await tester.tap(find.text('Person 2'));

    expect(taps.opened, ['TXN20002']);
  });

  testWidgets('balance loaded + transactions loading: panel beside shimmer', (
    tester,
  ) async {
    await pumpDashboard(tester, recent: const SectionLoading());

    expect(find.byType(BalancePanel), findsOneWidget);
    expect(find.byType(BalancePanelShimmer), findsNothing);
    expect(find.byType(TransactionRowShimmer), findsNWidgets(5));
    expect(find.byType(TransactionRow), findsNothing);
  });

  testWidgets('balance loading + transactions loaded: shimmer beside rows', (
    tester,
  ) async {
    await pumpDashboard(tester, balance: const SectionLoading());

    expect(find.byType(BalancePanelShimmer), findsOneWidget);
    expect(find.byType(BalancePanel), findsNothing);
    expect(find.byType(TransactionRow), findsNWidgets(5));
    expect(find.byType(TransactionRowShimmer), findsNothing);
  });

  testWidgets('loading shows five row shimmers, never a page spinner', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      profile: const SectionLoading(),
      balance: const SectionLoading(),
      recent: const SectionLoading(),
    );

    expect(find.byType(TransactionRowShimmer), findsNWidgets(5));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('quick actions render immediately and never shimmer', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      profile: const SectionLoading(),
      balance: const SectionLoading(),
      recent: const SectionLoading(),
    );

    expect(find.byType(QuickActionCard), findsNWidgets(3));
    expect(
      find.descendant(
        of: find.byType(QuickActionCard),
        matching: find.byType(ShimmerBox),
      ),
      findsNothing,
    );
  });

  testWidgets('pull-to-refresh fires onRefresh and keeps content visible', (
    tester,
  ) async {
    final taps = await pumpDashboard(tester);

    await tester.fling(find.text('Zed Q Tester'), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(taps.refresh, 1);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byType(BalancePanel), findsOneWidget);
    expect(find.byType(TransactionRow), findsNWidgets(5));
    expect(find.byType(ShimmerBox), findsNothing);

    taps.refreshDone.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('error states render ErrorStateView and Retry fires', (
    tester,
  ) async {
    final taps = await pumpDashboard(
      tester,
      balance: const SectionFailed('Check the backend is running.'),
      recent: const SectionFailed('Check the backend is running.'),
    );

    expect(find.byType(ErrorStateView), findsNWidgets(2));
    await tester.tap(find.text('Retry').first);
    await tester.tap(find.text('Retry').last);

    expect((taps.retryBalance, taps.retryList), (1, 1));
  });

  testWidgets('empty list renders the empty state', (tester) async {
    await pumpDashboard(tester, recent: const SectionLoaded([]));

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final loading in [false, true]) {
      testWidgets('no overflow at ${size.width}x${size.height}'
          '${loading ? ' while loading' : ''}', (tester) async {
        await pumpDashboard(
          tester,
          size: size,
          profile: loading ? const SectionLoading() : profile,
          balance: loading ? const SectionLoading() : balance,
          recent: loading ? const SectionLoading() : null,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
