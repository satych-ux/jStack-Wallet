import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/presentation/section.dart';
import 'package:j_stack_flutter_app/core/theme/app_colors.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';
import 'package:j_stack_flutter_app/core/widgets/detail_card.dart';
import 'package:j_stack_flutter_app/core/widgets/error_state_view.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/detail_card_shimmer.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:j_stack_flutter_app/core/widgets/status_label.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/models/transaction_details_view.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/screens/transaction_details_screen.dart';

const debit = TransactionDetailsView(
  id: 'TXN99042',
  direction: TxnDirection.debit,
  status: StatusKind.success,
  amount: '₹1,234.50',
  name: 'Zed Q Tester',
  mobileNumber: '+91 9000000042',
  dateTime: '20 Oct 2026, 16:00',
  remarks: 'Test remark',
);

const credit = TransactionDetailsView(
  id: 'TXN99043',
  direction: TxnDirection.credit,
  status: StatusKind.pending,
  amount: '₹500.00',
  name: 'Amy Sender',
  mobileNumber: '+91 9000000043',
  dateTime: '19 Oct 2026, 09:30',
);

class Calls {
  int back = 0, retry = 0;
}

Future<Calls> pumpDetails(
  WidgetTester tester, {
  Section<TransactionDetailsView> details = const SectionLoaded(debit),
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calls = Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: TransactionDetailsScreen(
        details: details,
        onBack: () => calls.back++,
        onRetry: () => calls.retry++,
      ),
    ),
  );
  return calls;
}

/// A circle filled with [color].
Finder dot(Color color) => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  return d is BoxDecoration && d.shape == BoxShape.circle && d.color == color;
});

String rowValue(WidgetTester tester, String label) =>
    tester.widget<DetailRow>(find.widgetWithText(DetailRow, label)).value;

void main() {
  testWidgets('debit: DEBIT pill with a brand dot and a minus amount', (
    tester,
  ) async {
    await pumpDetails(tester);

    expect(find.text('DEBIT'), findsWidgets); // pill and TYPE row
    expect(dot(AppColors.brand), findsOneWidget);
    expect(dot(AppColors.success), findsNothing);
    expect(find.text('−₹1,234.50'), findsOneWidget);
  });

  testWidgets('credit: CREDIT pill with a success dot and a plus amount', (
    tester,
  ) async {
    await pumpDetails(tester, details: const SectionLoaded(credit));

    expect(find.text('CREDIT'), findsWidgets);
    expect(dot(AppColors.success), findsOneWidget);
    expect(dot(AppColors.brand), findsNothing);
    expect(find.text('+₹500.00'), findsOneWidget);
  });

  testWidgets('all six rows render', (tester) async {
    await pumpDetails(tester);

    expect(find.byType(DetailRow), findsNWidgets(6));
    expect(rowValue(tester, 'TRANSACTION ID'), 'TXN99042');
    expect(rowValue(tester, 'BENEFICIARY'), 'Zed Q Tester');
    expect(rowValue(tester, 'MOBILE'), '+91 9000000042');
    expect(rowValue(tester, 'TYPE'), 'DEBIT');
    expect(rowValue(tester, 'DATE AND TIME'), '20 Oct 2026, 16:00');
    expect(rowValue(tester, 'REMARKS'), 'Test remark');
  });

  testWidgets('no remarks hides that row instead of showing it empty', (
    tester,
  ) async {
    await pumpDetails(tester, details: const SectionLoaded(credit));

    expect(find.text('REMARKS'), findsNothing);
    expect(find.byType(DetailRow), findsNWidgets(5));
  });

  testWidgets('a credit names the other party as SENDER', (tester) async {
    await pumpDetails(tester, details: const SectionLoaded(credit));

    expect(rowValue(tester, 'SENDER'), 'Amy Sender');
    expect(find.text('BENEFICIARY'), findsNothing);
  });

  testWidgets('status renders large in its colour', (tester) async {
    await pumpDetails(tester, details: const SectionLoaded(credit));

    final status = tester.widget<StatusLabel>(find.byType(StatusLabel));
    expect(status.status, StatusKind.pending);
    expect(status.large, isTrue);
    final text = tester.widget<Text>(find.text('PENDING'));
    expect(text.style!.color, AppColors.inkFaint);
  });

  testWidgets('loading shows the card shimmer and a shimmered hero', (
    tester,
  ) async {
    await pumpDetails(tester, details: const SectionLoading());

    expect(find.byType(DetailCardShimmer), findsOneWidget);
    // Pill, amount and status placeholders above the card.
    final heroBoxes = find.descendant(
      of: find.byType(ShimmerGroup),
      matching: find.byType(ShimmerBox),
    );
    // 12 in the card; pill dot + label, amount, status above it.
    expect(heroBoxes, findsNWidgets(12 + 4));
    expect(find.byType(DetailRow), findsNothing);
    expect(find.byType(StatusLabel), findsNothing);
  });

  testWidgets('the card does not jump when details arrive', (tester) async {
    await pumpDetails(tester, details: const SectionLoading());
    final loadingTop = tester.getTopLeft(find.byType(DetailCardShimmer)).dy;

    await pumpDetails(tester);
    final loadedTop = tester.getTopLeft(find.byType(DetailCard)).dy;

    expect(loadedTop, loadingTop);
  });

  testWidgets('the back arrow and Back to transactions both fire', (
    tester,
  ) async {
    final calls = await pumpDetails(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.tap(find.text('Back to transactions'));

    expect(calls.back, 2);
  });

  testWidgets('a failed load shows ErrorStateView; Retry and back work', (
    tester,
  ) async {
    final calls = await pumpDetails(
      tester,
      details: const SectionFailed('This transaction does not exist.'),
    );

    expect(find.byType(ErrorStateView), findsOneWidget);
    expect(find.text('This transaction does not exist.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Back to transactions'));

    expect((calls.retry, calls.back), (1, 1));
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final loading in [false, true]) {
      testWidgets('no overflow at ${size.width}x${size.height}'
          '${loading ? ' while loading' : ''}', (tester) async {
        await pumpDetails(
          tester,
          size: size,
          details: loading
              ? const SectionLoading()
              : const SectionLoaded(debit),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
