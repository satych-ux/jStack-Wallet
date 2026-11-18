import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_colors.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';
import 'package:j_stack_flutter_app/core/widgets/detail_card.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_button.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/models/transfer_result_view.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/screens/transfer_result_screen.dart';

const success = TransferSucceededView(
  amount: '₹1,234.50',
  beneficiaryName: 'Zed Q Tester',
  reference: 'TXN99042',
  dateTime: '20 Oct 2026, 16:04',
  updatedBalance: '₹8,765.50',
);

const insufficient = TransferFailedView(
  reason: 'INSUFFICIENT BALANCE',
  explanation: 'You tried to send ₹30,000.00 but ₹25,450.75 is available.',
  beneficiaryName: 'Zed Q Tester',
  statusCode: '409',
  balance: '₹25,450.75',
);

class Calls {
  int dashboard = 0, view = 0, retry = 0, edit = 0;
}

/// An unknown outcome: the one kind of failure a retry can fix.
const timedOut = TransferFailedView(
  reason: 'NOT CONFIRMED',
  explanation: 'The wallet did not answer in time.',
  beneficiaryName: 'Zed Q Tester',
  subtitle: 'We could not confirm the transfer.',
  canRetry: true,
);

Future<Calls> pumpResult(
  WidgetTester tester,
  TransferResultView result, {
  bool isRetrying = false,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calls = Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: TransferResultScreen(
        result: result,
        isRetrying: isRetrying,
        onBackToDashboard: () => calls.dashboard++,
        onViewTransaction: () => calls.view++,
        onTryAgain: () => calls.retry++,
        onEditTransfer: () => calls.edit++,
      ),
    ),
  );
  return calls;
}

/// A circle filled with [color].
Finder circle(Color color) => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  return d is BoxDecoration && d.shape == BoxShape.circle && d.color == color;
});

String rowValue(WidgetTester tester, String label) =>
    tester.widget<DetailRow>(find.widgetWithText(DetailRow, label)).value;

Finder button(String label) => find.widgetWithText(JWalletButton, label);

void main() {
  group('success', () {
    testWidgets('check on a successTint halo, reference, time, status and '
        'updated balance', (tester) async {
      await pumpResult(tester, success);

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(circle(AppColors.successTint), findsOneWidget);
      expect(find.text('Transfer successful'), findsOneWidget);
      expect(rowValue(tester, 'REFERENCE'), 'TXN99042');
      expect(rowValue(tester, 'DATE AND TIME'), '20 Oct 2026, 16:04');
      final status = tester.widget<DetailRow>(
        find.widgetWithText(DetailRow, 'STATUS'),
      );
      expect(status.value, 'SUCCESS');
      expect(status.valueColor, AppColors.success);
      expect(rowValue(tester, 'UPDATED BALANCE'), '₹8,765.50');
    });

    testWidgets('the summary names the amount and beneficiary', (tester) async {
      await pumpResult(tester, success);

      expect(
        find.textContaining('₹1,234.50', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('sent to Zed Q Tester.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Back to dashboard and View transaction both fire', (
      tester,
    ) async {
      final calls = await pumpResult(tester, success);

      await tester.tap(button('Back to dashboard'));
      await tester.tap(button('View transaction'));

      expect((calls.dashboard, calls.view), (1, 1));
      expect(button('Try again'), findsNothing);
    });
  });

  group('failure', () {
    testWidgets('alert icon, brandTint banner, reason and status code', (
      tester,
    ) async {
      await pumpResult(tester, insufficient);

      expect(find.byIcon(Icons.priority_high), findsOneWidget);
      expect(circle(AppColors.brandTint), findsOneWidget);
      expect(find.text('Transfer not completed'), findsOneWidget);
      expect(find.text('INSUFFICIENT BALANCE'), findsOneWidget);
      expect(
        find.text('You tried to send ₹30,000.00 but ₹25,450.75 is available.'),
        findsOneWidget,
      );
      final banner = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('INSUFFICIENT BALANCE'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(banner.color, AppColors.brandTint);
      expect(rowValue(tester, 'RESPONSE'), '409');
    });

    testWidgets('the unchanged balance renders', (tester) async {
      await pumpResult(tester, insufficient);

      expect(rowValue(tester, 'BALANCE'), '₹25,450.75');
      expect(
        find.text('Your wallet was not debited. Nothing has changed.'),
        findsOneWidget,
      );
    });

    testWidgets('insufficient balance offers Edit transfer, not a retry that would fail again', (tester) async {
      final calls = await pumpResult(tester, insufficient);

      expect(button('Try again'), findsNothing);
      await tester.tap(button('Edit transfer'));
      await tester.tap(button('Back to dashboard'));

      expect((calls.edit, calls.retry, calls.dashboard), (1, 0, 1));
    });

    testWidgets('Try again and Back to dashboard both fire', (tester) async {
      final calls = await pumpResult(tester, timedOut);

      await tester.tap(button('Try again'));
      await tester.tap(button('Back to dashboard'));

      expect((calls.retry, calls.dashboard), (1, 1));
      expect(button('View transaction'), findsNothing);
    });

    testWidgets('while retrying, Try again spins and ignores taps', (
      tester,
    ) async {
      final calls = await pumpResult(tester, timedOut, isRetrying: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(JWalletButton).first);

      expect(calls.retry, 0);
    });

    testWidgets('a timeout has no status code or balance and says so', (
      tester,
    ) async {
      await pumpResult(
        tester,
        const TransferFailedView(
          reason: 'TIMED OUT',
          explanation: 'The server did not answer in time.',
          beneficiaryName: 'Zed Q Tester',
          subtitle: 'We could not confirm the transfer.',
        ),
      );

      expect(find.text('RESPONSE'), findsNothing);
      expect(find.text('BALANCE'), findsNothing);
      expect(find.text('We could not confirm the transfer.'), findsOneWidget);
      expect(
        find.text('Your wallet was not debited. Nothing has changed.'),
        findsNothing,
      );
    });
  });

  testWidgets('one screen class renders both outcomes', (tester) async {
    await pumpResult(tester, success);
    expect(find.byType(TransferResultScreen), findsOneWidget);

    await pumpResult(tester, insufficient);
    expect(find.byType(TransferResultScreen), findsOneWidget);
  });

  testWidgets('system back goes to the dashboard, not confirmation', (
    tester,
  ) async {
    final calls = await pumpResult(tester, success);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(calls.dashboard, 1);
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final result in <TransferResultView>[success, insufficient]) {
      testWidgets('no overflow at ${size.width}x${size.height} '
          '(${result.runtimeType})', (tester) async {
        await pumpResult(tester, result, size: size);

        expect(tester.takeException(), isNull);
      });
    }
  }
}
