import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_colors.dart';
import 'package:j_stack_flutter_app/core/widgets/app_top_bar.dart';
import 'package:j_stack_flutter_app/core/widgets/balance_panel.dart';
import 'package:j_stack_flutter_app/core/widgets/detail_card.dart';
import 'package:j_stack_flutter_app/core/widgets/empty_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/error_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/quick_action_card.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_rail.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';

import 'fixtures.dart';
import 'pump.dart';

void main() {
  group('TransactionRow', () {
    testWidgets('debit shows a minus and a brand dot', (tester) async {
      await pumpInApp(tester, const TransactionRow(data: debitRow));

      expect(find.text('−1,500.00'), findsOneWidget);
      expect(findDot(AppColors.brand), findsOneWidget);
      expect(findDot(AppColors.success), findsNothing);
    });

    testWidgets('credit shows a plus and a success dot', (tester) async {
      await pumpInApp(tester, const TransactionRow(data: creditRow));

      expect(find.text('+5,000.00'), findsOneWidget);
      expect(findDot(AppColors.success), findsOneWidget);
      expect(findDot(AppColors.brand), findsNothing);
    });

    testWidgets('reference and date both render', (tester) async {
      await pumpInApp(tester, const TransactionRow(data: debitRow));

      expect(find.text('TXN10001'), findsOneWidget);
      expect(find.text('20 Oct'), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        TransactionRow(data: debitRow, onTap: () => taps++),
      );

      await tester.tap(find.byType(TransactionRow));
      expect(taps, 1);
    });

    testWidgets('rail renders its rows through ListView.builder', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TransactionRail(
          itemCount: 2,
          itemBuilder: (context, i) =>
              TransactionRow(data: i == 0 ? debitRow : creditRow),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TransactionRow), findsNWidgets(2));
    });
  });

  group('BalancePanel', () {
    testWidgets('renders amount, wallet id and masked account on ink', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const BalancePanel(
          balance: '₹25,450.75',
          walletId: 'WALLET10001',
          maskedAccount: 'XXXX XXXX 4589',
        ),
      );

      expect(find.text('₹25,450.75'), findsOneWidget);
      expect(find.text('WALLET10001'), findsOneWidget);
      expect(find.text('XXXX XXXX 4589'), findsOneWidget);
      expect(
        firstDecoration(tester, find.byType(BalancePanel)).color,
        AppColors.ink,
      );
    });
  });

  group('QuickActionCard', () {
    testWidgets('enabled fires onTap', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        QuickActionCard(
          icon: Icons.north_east,
          label: 'Send money',
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.byType(QuickActionCard));
      expect(taps, 1);
      expect(find.text('SOON'), findsNothing);
    });

    testWidgets('coming soon shows SOON and does not fire', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        QuickActionCard(
          icon: Icons.add,
          label: 'Add money',
          onTap: () => taps++,
          isComingSoon: true,
        ),
      );

      expect(find.text('SOON'), findsOneWidget);
      await tester.tap(find.byType(QuickActionCard));
      expect(taps, 0);
    });
  });

  group('EmptyStateView and ErrorStateView', () {
    testWidgets('empty renders its copy', (tester) async {
      await pumpInApp(
        tester,
        const EmptyStateView(
          title: 'No transactions yet',
          message: 'Your first transfer will appear here.',
        ),
      );

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Your first transfer will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('error renders its copy and Retry fires', (tester) async {
      var retries = 0;
      await pumpInApp(
        tester,
        ErrorStateView(
          title: 'Could not reach the wallet',
          message: 'Check the backend is running.',
          onRetry: () => retries++,
        ),
      );

      expect(find.text('Could not reach the wallet'), findsOneWidget);
      expect(find.text('Check the backend is running.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });
  });

  group('DetailCard', () {
    testWidgets('renders every row with a line border', (tester) async {
      await pumpInApp(
        tester,
        const DetailCard(
          rows: [
            DetailRow(label: 'TRANSACTION ID', value: 'TXN10001'),
            DetailRow(
              label: 'BENEFICIARY',
              value: 'Rahul Sharma',
              kind: DetailValueKind.name,
            ),
          ],
        ),
      );

      expect(find.text('TXN10001'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(styleOf(tester, 'TXN10001').fontFamily, 'Space Mono');
      expect(styleOf(tester, 'Rahul Sharma').fontFamily, 'Manrope');
      final border =
          firstDecoration(tester, find.byType(DetailCard)).border! as Border;
      expect(border.top.color, AppColors.line);
    });
  });

  group('AppTopBar', () {
    testWidgets('shows the title and back fires', (tester) async {
      var backs = 0;
      await pumpInApp(
        tester,
        AppTopBar(title: 'Send money', onBack: () => backs++),
      );

      expect(find.text('Send money'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      expect(backs, 1);
    });
  });
}
