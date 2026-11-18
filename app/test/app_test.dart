import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/widgets/app_top_bar.dart';
import 'package:j_stack_flutter_app/core/widgets/balance_panel.dart';
import 'package:j_stack_flutter_app/core/widgets/transaction_row.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/screens/transaction_details_screen.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/screens/transfer_result_screen.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_button.dart';
import 'package:j_stack_flutter_app/features/auth/presentation/screens/login_screen.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/screens/confirm_transfer_screen.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/screens/send_money_screen.dart';
import 'package:j_stack_flutter_app/features/wallet/presentation/screens/dashboard_screen.dart';
import 'package:j_stack_flutter_app/main.dart';

/// Lets a navigation and its page transition finish. Not pumpAndSettle:
/// screens shimmer until the data slice, so the tree never settles.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(JWalletButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await settle(tester);
}

Future<void> startSignedIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const JWalletApp(fakeLatency: Duration.zero));
  await settle(tester);
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'demo@jstack.co');
  await tester.enterText(fields.at(1), 'Demo@123');
  await tapButton(tester, 'Sign in');
}

void main() {
  testWidgets('the app starts on login', (tester) async {
    await tester.pumpWidget(const JWalletApp(fakeLatency: Duration.zero));
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('invalid login input stays on login', (tester) async {
    await tester.pumpWidget(const JWalletApp(fakeLatency: Duration.zero));
    await settle(tester);

    await tapButton(tester, 'Sign in');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('signing in lands on the dashboard', (tester) async {
    await startSignedIn(tester);

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('dashboard → send money → confirmation → back', (tester) async {
    await startSignedIn(tester);

    await tester.tap(find.text('Send money'));
    await settle(tester);
    expect(find.byType(SendMoneyScreen), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1500');
    await tester.enterText(fields.at(1), 'Rahul Sharma');
    await tester.enterText(fields.at(2), '9876543210');
    await tapButton(tester, 'Review transfer');

    expect(find.byType(ConfirmTransferScreen), findsOneWidget);
    expect(find.text('₹1,500.00'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);
    final key = tester
        .widget<ConfirmTransferScreen>(find.byType(ConfirmTransferScreen))
        .requestKey;
    expect(key, matches(RegExp(r'^[0-9a-f-]{36}$')));

    await tapButton(tester, 'Edit details');
    expect(find.byType(SendMoneyScreen), findsOneWidget);
  });

  testWidgets('the request key survives a rebuild of the confirm screen', (
    tester,
  ) async {
    await startSignedIn(tester);
    await tester.tap(find.text('Send money'));
    await settle(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '10');
    await tester.enterText(fields.at(1), 'A');
    await tester.enterText(fields.at(2), '9876543210');
    await tapButton(tester, 'Review transfer');
    String key() => tester
        .widget<ConfirmTransferScreen>(find.byType(ConfirmTransferScreen))
        .requestKey;
    final first = key();

    // Force the route to rebuild (e.g. a theme or media change).
    tester.view.physicalSize = const Size(430, 932);
    await settle(tester);

    expect(key(), first);
  });

  testWidgets('dashboard → history → back to dashboard', (tester) async {
    await startSignedIn(tester);

    await tester.tap(find.text('See all'));
    await settle(tester);
    expect(find.byType(TransactionsScreen), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AppTopBar),
        matching: find.byTooltip('Back'),
      ),
    );
    await settle(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('the dashboard shows the fake wallet, user and activity', (
    tester,
  ) async {
    await startSignedIn(tester);
    await settle(tester);

    expect(find.text('Aditi Verma'), findsOneWidget);
    expect(find.text('AV'), findsOneWidget);
    final panel = tester.widget<BalancePanel>(find.byType(BalancePanel));
    expect(panel.balance, '₹24,850.75');
    expect(find.byType(TransactionRow), findsNWidgets(5));
  });

  testWidgets('confirming a transfer lands on the success result', (
    tester,
  ) async {
    await startSignedIn(tester);
    await tester.tap(find.text('Send money'));
    await settle(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1500');
    await tester.enterText(fields.at(1), 'Rahul Sharma');
    await tester.enterText(fields.at(2), '9876543210');
    await tapButton(tester, 'Review transfer');

    await tapButton(tester, 'Confirm transfer');
    await settle(tester);

    expect(find.byType(TransferResultScreen), findsOneWidget);
    expect(find.text('Transfer successful'), findsOneWidget);
    // From the fake transfer response, not calculated in the app.
    expect(find.text('₹23,350.75'), findsOneWidget);

    await tapButton(tester, 'View transaction');
    await settle(tester);
    expect(find.byType(TransactionDetailsScreen), findsOneWidget);
    expect(find.text('TXN10006'), findsOneWidget);
  });

  testWidgets('history lists the fake transactions and opens details', (
    tester,
  ) async {
    await startSignedIn(tester);
    await tester.tap(find.text('History'));
    await settle(tester);
    await settle(tester);

    expect(find.byType(TransactionRow), findsNWidgets(6));
    await tester.tap(find.text('Kavya Iyer'));
    await settle(tester);
    await settle(tester);

    expect(find.byType(TransactionDetailsScreen), findsOneWidget);
    expect(find.text('TXN10003'), findsOneWidget);
  });
}
