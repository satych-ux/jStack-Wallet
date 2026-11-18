import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';
import 'package:j_stack_flutter_app/core/widgets/detail_card.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_button.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/models/confirmation_view.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/screens/confirm_transfer_screen.dart';

const details = ConfirmationView(
  amount: '₹1,234.50',
  beneficiaryName: 'Zed Q Tester',
  mobileNumber: '+91 9000000042',
  remarks: 'Test remark',
  balanceAfter: '₹8,765.50',
);

const requestKey = '4f2a9c1e-77b3-4c1d-9e0a-1b2c3d4e5f60';

class Calls {
  int confirm = 0;
  int back = 0;
}

Future<Calls> pumpConfirm(
  WidgetTester tester, {
  ConfirmationView view = details,
  bool isSubmitting = false,
  Calls? calls,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = calls ?? Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: ConfirmTransferScreen(
        details: view,
        requestKey: requestKey,
        isSubmitting: isSubmitting,
        onConfirm: () => c.confirm++,
        onBack: () => c.back++,
      ),
    ),
  );
  return c;
}

Finder button(String label) => find.widgetWithText(JWalletButton, label);

String rowValue(WidgetTester tester, String label) =>
    tester.widget<DetailRow>(find.widgetWithText(DetailRow, label)).value;

void main() {
  testWidgets('amount and every detail row render from the model', (
    tester,
  ) async {
    await pumpConfirm(tester);

    expect(find.text('YOU ARE SENDING'), findsOneWidget);
    expect(find.text('₹1,234.50'), findsOneWidget);
    expect(find.text('to Zed Q Tester'), findsOneWidget);
    expect(rowValue(tester, 'BENEFICIARY'), 'Zed Q Tester');
    expect(rowValue(tester, 'MOBILE'), '+91 9000000042');
    expect(rowValue(tester, 'REMARKS'), 'Test remark');
    expect(rowValue(tester, 'BALANCE AFTER'), '₹8,765.50');
  });

  testWidgets('the fee row shows ₹0.00', (tester) async {
    await pumpConfirm(tester);

    expect(rowValue(tester, 'TRANSFER FEE'), '₹0.00');
  });

  testWidgets('without a server-provided balance-after, that row is hidden', (
    tester,
  ) async {
    await pumpConfirm(
      tester,
      view: const ConfirmationView(
        amount: '₹1,234.50',
        beneficiaryName: 'Zed Q Tester',
        mobileNumber: '+91 9000000042',
      ),
    );

    expect(find.text('BALANCE AFTER'), findsNothing);
    expect(find.text('REMARKS'), findsNothing);
    expect(find.text('TRANSFER FEE'), findsOneWidget);
  });

  testWidgets('the request key renders', (tester) async {
    await pumpConfirm(tester);

    expect(find.text('REQUEST KEY'), findsOneWidget);
    expect(find.text(requestKey), findsOneWidget);
  });

  testWidgets('Confirm fires once; a tap while submitting does not', (
    tester,
  ) async {
    final calls = await pumpConfirm(tester);

    await tester.tap(button('Confirm transfer'));
    expect(calls.confirm, 1);

    // The caller reports the request is in flight.
    await pumpConfirm(tester, isSubmitting: true, calls: calls);
    await tester.tap(find.byType(JWalletButton).first);
    await tester.tap(find.byType(JWalletButton).first);

    expect(calls.confirm, 1);
  });

  testWidgets('isSubmitting shows the loading button', (tester) async {
    await pumpConfirm(tester, isSubmitting: true);

    final confirm = tester.widget<JWalletButton>(
      find.byType(JWalletButton).first,
    );
    expect(confirm.variant, JWalletButtonVariant.loading);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Edit details and the back arrow fire the back callback', (
    tester,
  ) async {
    final calls = await pumpConfirm(tester);

    await tester.tap(button('Edit details'));
    await tester.tap(find.byTooltip('Back'));

    expect(calls.back, 2);
  });

  testWidgets('while submitting, Edit details and back do nothing', (
    tester,
  ) async {
    final calls = await pumpConfirm(tester, isSubmitting: true);

    await tester.tap(button('Edit details'));
    await tester.tap(find.byTooltip('Back'));

    expect(calls.back, 0);
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    testWidgets('no overflow at ${size.width}x${size.height}', (tester) async {
      await pumpConfirm(tester, size: size);

      expect(tester.takeException(), isNull);
    });
  }
}
