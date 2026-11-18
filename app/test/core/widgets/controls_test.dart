import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_colors.dart';
import 'package:j_stack_flutter_app/core/widgets/filter_pill.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_button.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_text_field.dart';
import 'package:j_stack_flutter_app/core/widgets/status_label.dart';

import 'pump.dart';

void main() {
  group('JWalletButton', () {
    testWidgets('primary renders its label and fires once per tap', (
      tester,
    ) async {
      var taps = 0;
      await pumpInApp(
        tester,
        JWalletButton(label: 'Confirm transfer', onPressed: () => taps++),
      );

      expect(find.text('Confirm transfer'), findsOneWidget);
      await tester.tap(find.byType(JWalletButton));
      expect(taps, 1);
    });

    testWidgets('disabled variant does not fire', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        JWalletButton(
          label: 'Disabled',
          onPressed: () => taps++,
          variant: JWalletButtonVariant.disabled,
        ),
      );

      await tester.tap(find.byType(JWalletButton));
      expect(taps, 0);
    });

    testWidgets('loading variant shows a spinner and does not fire', (
      tester,
    ) async {
      var taps = 0;
      await pumpInApp(
        tester,
        JWalletButton(
          label: 'Sending',
          onPressed: () => taps++,
          variant: JWalletButtonVariant.loading,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(JWalletButton));
      expect(taps, 0);
    });

    testWidgets('secondary has a line border', (tester) async {
      await pumpInApp(
        tester,
        JWalletButton(
          label: 'Edit details',
          onPressed: () {},
          variant: JWalletButtonVariant.secondary,
        ),
      );

      final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
      final side = style.side!.resolve(<WidgetState>{})!;
      expect(side.color, AppColors.line);
      expect(side.width, 1);
    });
  });

  group('JWalletTextField', () {
    testWidgets('renders label and hint', (tester) async {
      await pumpInApp(
        tester,
        const JWalletTextField(label: 'BENEFICIARY', hint: 'Beneficiary name'),
      );

      expect(find.text('BENEFICIARY'), findsOneWidget);
      expect(find.text('Beneficiary name'), findsOneWidget);
    });

    testWidgets('error shows the message and a brand border', (tester) async {
      await pumpInApp(
        tester,
        const JWalletTextField(
          label: 'MOBILE',
          errorText: 'Enter a valid 10-digit mobile number',
        ),
      );

      expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
      final decoration = firstDecoration(tester, find.byType(JWalletTextField));
      expect((decoration.border! as Border).top.color, AppColors.brand);
    });

    testWidgets('eye toggle flips obscureText', (tester) async {
      await pumpInApp(
        tester,
        const JWalletTextField(
          label: 'PASSWORD',
          kind: JWalletFieldKind.password,
        ),
      );

      bool obscured() =>
          tester.widget<TextField>(find.byType(TextField)).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(obscured(), isTrue);
    });
  });

  group('AmountField', () {
    testWidgets('shows the rupee prefix and types in Space Mono 700', (
      tester,
    ) async {
      await pumpInApp(tester, const AmountField());

      expect(find.text('₹'), findsOneWidget);
      final style = tester.widget<TextField>(find.byType(TextField)).style!;
      expect(style.fontFamily, 'Space Mono');
      expect(style.fontWeight, FontWeight.w700);
    });
  });

  group('StatusLabel', () {
    testWidgets('each status has its colour', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            StatusLabel(status: StatusKind.success),
            StatusLabel(status: StatusKind.pending),
            StatusLabel(status: StatusKind.failed),
          ],
        ),
      );

      expect(styleOf(tester, 'SUCCESS').color, AppColors.success);
      expect(styleOf(tester, 'PENDING').color, AppColors.inkFaint);
      expect(styleOf(tester, 'FAILED').color, AppColors.brand);
    });
  });

  group('FilterPill', () {
    testWidgets('selected is ink with a white label; unselected inverts', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        Row(
          children: [
            FilterPill(label: 'All', selected: true, onTap: () {}),
            FilterPill(label: 'Debit', selected: false, onTap: () {}),
          ],
        ),
      );

      final all = find.widgetWithText(FilterPill, 'All');
      final debit = find.widgetWithText(FilterPill, 'Debit');
      expect(firstDecoration(tester, all).color, AppColors.ink);
      expect(styleOf(tester, 'All').color, AppColors.white);
      expect(firstDecoration(tester, debit).color, AppColors.white);
      expect(styleOf(tester, 'Debit').color, AppColors.ink);
    });

    testWidgets('fires onTap', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        FilterPill(label: 'Credit', selected: false, onTap: () => taps++),
      );

      await tester.tap(find.byType(FilterPill));
      expect(taps, 1);
    });
  });
}
