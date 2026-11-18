import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/presentation/section.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_button.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_text_field.dart';
import 'package:j_stack_flutter_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/models/transfer_draft.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/screens/send_money_screen.dart';

Future<List<TransferDraft>> pumpSend(
  WidgetTester tester, {
  Section<String> availableBalance = const SectionLoaded('₹25,450.75'),
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final submitted = <TransferDraft>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: SendMoneyScreen(
        availableBalance: availableBalance,
        onSubmit: submitted.add,
        onBack: () {},
      ),
    ),
  );
  return submitted;
}

/// Fields in screen order: amount, beneficiary, mobile, remarks.
Finder field(int index) => find.byType(TextField).at(index);

Future<void> fill(
  WidgetTester tester, {
  String amount = '1500',
  String name = 'Rahul Sharma',
  String mobile = '9876543210',
  String remarks = '',
}) async {
  await tester.enterText(field(0), amount);
  await tester.enterText(field(1), name);
  await tester.enterText(field(2), mobile);
  await tester.enterText(field(3), remarks);
}

Future<void> review(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(JWalletButton));
  await tester.tap(find.byType(JWalletButton));
  await tester.pump();
}

void main() {
  testWidgets('fields render in order: Amount, Beneficiary, Mobile, Remarks', (
    tester,
  ) async {
    await pumpSend(tester);

    final labels = ['AMOUNT', 'BENEFICIARY NAME', 'MOBILE NUMBER', 'REMARKS'];
    final tops = [for (final l in labels) tester.getTopLeft(find.text(l)).dy];
    expect(tops, [...tops]..sort());
    expect(find.byType(AmountField), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('the balance strip shows the passed-in value', (tester) async {
    await pumpSend(tester, availableBalance: const SectionLoaded('₹1,234.56'));

    expect(find.text('AVAILABLE'), findsOneWidget);
    expect(find.text('₹1,234.56'), findsOneWidget);
  });

  testWidgets('while the balance loads only the strip shimmers', (
    tester,
  ) async {
    await pumpSend(tester, availableBalance: const SectionLoading());

    expect(find.byType(ShimmerBox), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(JWalletTextField),
        matching: find.byType(ShimmerBox),
      ),
      findsNothing,
    );
    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('empty beneficiary blocks submit and shows its error', (
    tester,
  ) async {
    final submitted = await pumpSend(tester);
    await fill(tester, name: '   ');

    await review(tester);

    expect(find.text("Enter the beneficiary's name"), findsOneWidget);
    expect(submitted, isEmpty);
  });

  for (final mobile in ['987654321', '98765432101', '98765abcde']) {
    testWidgets('mobile "$mobile" shows the 10-digit error', (tester) async {
      final submitted = await pumpSend(tester);
      await fill(tester, mobile: mobile);

      await review(tester);

      expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
      expect(submitted, isEmpty);
    });
  }

  for (final amount in ['0', '-5', 'abc']) {
    testWidgets('amount "$amount" shows the greater-than-zero error', (
      tester,
    ) async {
      final submitted = await pumpSend(tester);
      await fill(tester, amount: amount);

      await review(tester);

      expect(find.text('Enter an amount greater than zero'), findsOneWidget);
      expect(submitted, isEmpty);
    });
  }

  testWidgets('an amount with three decimals is rejected', (tester) async {
    final submitted = await pumpSend(tester);
    await fill(tester, amount: '10.123');

    await review(tester);

    expect(find.text('Use at most 2 decimal places'), findsOneWidget);
    expect(submitted, isEmpty);
  });

  testWidgets('empty remarks are valid and arrive as null', (tester) async {
    final submitted = await pumpSend(tester);
    await fill(tester, remarks: '');

    await review(tester);

    expect(submitted, hasLength(1));
    expect(submitted.single.remarks, isNull);
  });

  testWidgets('valid input fires once with trimmed values', (tester) async {
    final submitted = await pumpSend(tester);
    await fill(
      tester,
      amount: ' 1500.50 ',
      name: '  Rahul Sharma ',
      mobile: ' 9876543210',
      remarks: ' Dinner ',
    );

    await review(tester);

    expect(submitted, hasLength(1));
    final draft = submitted.single;
    expect(draft.amount, '1500.50');
    expect(draft.beneficiaryName, 'Rahul Sharma');
    expect(draft.mobileNumber, '9876543210');
    expect(draft.remarks, 'Dinner');
  });

  testWidgets('an amount above the balance is not blocked', (tester) async {
    final submitted = await pumpSend(
      tester,
      availableBalance: const SectionLoaded('₹100.00'),
    );
    await fill(tester, amount: '5000');

    await review(tester);

    expect(submitted, hasLength(1));
  });

  testWidgets('a field error clears once that field is edited', (tester) async {
    await pumpSend(tester);
    await review(tester);
    expect(find.text("Enter the beneficiary's name"), findsOneWidget);

    await tester.enterText(field(1), 'R');
    await tester.pump();

    expect(find.text("Enter the beneficiary's name"), findsNothing);
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    testWidgets('no overflow at ${size.width}x${size.height} with all errors', (
      tester,
    ) async {
      await pumpSend(tester, size: size);
      await fill(tester, amount: '', name: '', mobile: '1', remarks: 'a' * 101);
      await review(tester);

      expect(tester.takeException(), isNull);
    });
  }
}
