import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/widgets/app_top_bar.dart';
import 'package:j_stack_flutter_app/core/widgets/balance_panel.dart';
import 'package:j_stack_flutter_app/core/widgets/detail_card.dart';
import 'package:j_stack_flutter_app/core/widgets/empty_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/error_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/filter_pill.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_button.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_text_field.dart';
import 'package:j_stack_flutter_app/core/widgets/quick_action_card.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/balance_panel_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/detail_card_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/transaction_row_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_rail.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';

import 'fixtures.dart';
import 'pump.dart';

/// Every shared widget, stacked, with long-ish real values.
Widget _everything() {
  return SingleChildScrollView(
    child: Column(
      children: [
        AppTopBar(title: 'Transaction details for review', onBack: () {}),
        const BalancePanel(
          balance: '₹1,25,45,450.75',
          walletId: 'WALLET10001',
          maskedAccount: 'XXXX XXXX 4589',
        ),
        const ShimmerGroup(child: BalancePanelShimmer()),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.north_east,
                label: 'Send money',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: QuickActionCard(
                icon: Icons.add,
                label: 'Add money',
                isComingSoon: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionCard(
                icon: Icons.notes,
                label: 'History',
                onTap: () {},
              ),
            ),
          ],
        ),
        TransactionRail(
          itemCount: 3,
          itemBuilder: (context, i) => i == 2
              ? const ShimmerGroup(child: TransactionRowShimmer())
              : TransactionRow(data: i == 0 ? debitRow : creditRow),
        ),
        Row(
          children: [
            FilterPill(label: 'All', selected: true, onTap: () {}),
            FilterPill(label: 'Credit', selected: false, onTap: () {}),
            FilterPill(label: 'Debit', selected: false, onTap: () {}),
          ],
        ),
        const JWalletTextField(
          label: 'MOBILE NUMBER',
          kind: JWalletFieldKind.phone,
          errorText: 'Enter a valid 10-digit mobile number',
        ),
        const JWalletTextField(
          label: 'PASSWORD',
          kind: JWalletFieldKind.password,
        ),
        const JWalletTextField(label: 'REMARKS', isOptional: true),
        const AmountField(),
        const DetailCard(
          rows: [
            DetailRow(
              label: 'BENEFICIARY',
              value: 'Rahul Sharma',
              kind: DetailValueKind.name,
            ),
            DetailRow(
              label: 'BALANCE AFTER',
              value: '₹23,950.75',
              kind: DetailValueKind.monoBold,
              emphasised: true,
            ),
          ],
        ),
        const ShimmerGroup(child: DetailCardShimmer()),
        const EmptyStateView(
          title: 'No transactions yet',
          message: 'Your first transfer will appear here.',
        ),
        ErrorStateView(
          title: 'Could not reach the wallet',
          message: 'Check the backend is running.',
          onRetry: () {},
        ),
        JWalletButton(
          label: 'Sending',
          onPressed: () {},
          variant: JWalletButtonVariant.loading,
        ),
      ],
    ),
  );
}

void main() {
  for (final width in [360.0, 430.0]) {
    testWidgets('every shared widget lays out at $width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpInApp(tester, _everything(), width: width);

      expect(tester.takeException(), isNull);
    });
  }
}
