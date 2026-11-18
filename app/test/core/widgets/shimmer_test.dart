import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_colors.dart';
import 'package:j_stack_flutter_app/core/widgets/balance_panel.dart';
import 'package:j_stack_flutter_app/core/widgets/detail_card.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/balance_panel_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/detail_card_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/transaction_row_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';

import 'fixtures.dart';
import 'pump.dart';

void main() {
  group('ShimmerBox', () {
    testWidgets('honours width, height and radius', (tester) async {
      await pumpInApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: ShimmerBox(width: 120, height: 11, radius: 6),
        ),
      );

      expect(tester.getSize(find.byType(ShimmerBox)), const Size(120, 11));
      expect(
        firstDecoration(tester, find.byType(ShimmerBox)).borderRadius,
        BorderRadius.circular(6),
      );
    });

    testWidgets('uses the light base by default and the dark base on dark', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            ShimmerBox(key: Key('light'), width: 10, height: 10),
            ShimmerBox(key: Key('dark'), width: 10, height: 10, onDark: true),
          ],
        ),
      );

      expect(
        firstDecoration(tester, find.byKey(const Key('light'))).color,
        AppColors.shimmerBase,
      );
      expect(
        firstDecoration(tester, find.byKey(const Key('dark'))).color,
        AppColors.shimmerBaseOnDark,
      );
    });
  });

  group('ShimmerGroup', () {
    testWidgets('many boxes share exactly one animation ticker', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        ShimmerGroup(
          child: Column(
            children: List.generate(
              20,
              (_) => const ShimmerBox(width: 40, height: 4),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ShimmerBox), findsNWidgets(20));
      // Every running ticker schedules one transient frame callback.
      expect(tester.binding.transientCallbackCount, 1);
    });

    testWidgets('wraps its section in a RepaintBoundary', (tester) async {
      await pumpInApp(
        tester,
        const ShimmerGroup(child: ShimmerBox(width: 40, height: 4)),
      );

      expect(
        find.descendant(
          of: find.byType(ShimmerGroup),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });
  });

  group('BalancePanelShimmer', () {
    testWidgets('is ink and the same height as a populated panel', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            BalancePanel(
              balance: '₹25,450.75',
              walletId: 'WALLET10001',
              maskedAccount: 'XXXX XXXX 4589',
            ),
            ShimmerGroup(child: BalancePanelShimmer()),
          ],
        ),
      );

      expect(
        firstDecoration(tester, find.byType(BalancePanelShimmer)).color,
        AppColors.ink,
      );
      expect(
        tester.getSize(find.byType(BalancePanelShimmer)).height,
        tester.getSize(find.byType(BalancePanel)).height,
      );
    });
  });

  group('TransactionRowShimmer', () {
    for (final density in RailDensity.values) {
      testWidgets('matches a populated row height (${density.name})', (
        tester,
      ) async {
        await pumpInApp(
          tester,
          Column(
            children: [
              TransactionRow(data: debitRow, density: density),
              ShimmerGroup(child: TransactionRowShimmer(density: density)),
            ],
          ),
        );

        expect(
          tester.getSize(find.byType(TransactionRowShimmer)).height,
          tester.getSize(find.byType(TransactionRow)).height,
        );
      });
    }
  });

  group('DetailCardShimmer', () {
    testWidgets('renders six rows inside the real card border', (tester) async {
      await pumpInApp(tester, const ShimmerGroup(child: DetailCardShimmer()));

      // Two boxes per row.
      expect(find.byType(ShimmerBox), findsNWidgets(12));
      final border =
          firstDecoration(tester, find.byType(DetailCardShimmer)).border!
              as Border;
      expect(border.top.color, AppColors.line);
    });

    testWidgets('row height matches a real DetailRow', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            DetailCard(
              rows: [DetailRow(label: 'TRANSACTION ID', value: 'TXN10001')],
            ),
            ShimmerGroup(child: DetailCardShimmer(rowCount: 1)),
          ],
        ),
      );

      expect(
        tester.getSize(find.byType(DetailCardShimmer)).height,
        tester.getSize(find.byType(DetailCard)).height,
      );
    });
  });
}
