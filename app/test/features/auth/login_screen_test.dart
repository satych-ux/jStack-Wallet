import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_colors.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';
import 'package:j_stack_flutter_app/core/widgets/brand_mark.dart';
import 'package:j_stack_flutter_app/core/widgets/jwallet_button.dart';
import 'package:j_stack_flutter_app/features/auth/presentation/screens/login_screen.dart';

/// Records every navigation push so a test can assert none happened.
class _PushRecorder extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

Future<void> pumpLogin(
  WidgetTester tester, {
  void Function(String email, String password)? onSubmit,
  bool isLoading = false,
  String? errorMessage,
  NavigatorObserver? observer,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      navigatorObservers: [?observer],
      home: LoginScreen(
        onSubmit: onSubmit ?? (_, _) {},
        isLoading: isLoading,
        errorMessage: errorMessage,
      ),
    ),
  );
}

/// Email is the first text field on the screen, password the second.
Finder field(String label) =>
    find.byType(TextField).at(label == 'EMAIL' ? 0 : 1);

Future<void> tapSignIn(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(JWalletButton));
  await tester.tap(find.byType(JWalletButton));
  await tester.pump();
}

void main() {
  testWidgets('renders brand mark, wordmark, headline, fields and button', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('jWallet Lite'), findsOneWidget);
    expect(find.text('Sign in to move money.'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(JWalletButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('password is obscured by default and the toggle reveals it', (
    tester,
  ) async {
    await pumpLogin(tester);

    bool obscured() => tester.widget<TextField>(field('PASSWORD')).obscureText;

    expect(obscured(), isTrue);
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(obscured(), isFalse);
  });

  testWidgets('empty email shows "Enter your email"', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(field('PASSWORD'), 'Demo@123');

    await tapSignIn(tester);

    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('malformed email shows the format error', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(field('EMAIL'), 'demo@jstack');
    await tester.enterText(field('PASSWORD'), 'Demo@123');

    await tapSignIn(tester);

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('empty password shows its error', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(field('EMAIL'), 'demo@jstack.co');

    await tapSignIn(tester);

    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('invalid input never calls submit', (tester) async {
    var calls = 0;
    await pumpLogin(tester, onSubmit: (_, _) => calls++);

    await tapSignIn(tester);

    expect(calls, 0);
  });

  testWidgets('a field error clears once the user edits that field', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tapSignIn(tester);
    expect(find.text('Enter your email'), findsOneWidget);

    await tester.enterText(field('EMAIL'), 'd');
    await tester.pump();

    expect(find.text('Enter your email'), findsNothing);
  });

  testWidgets('valid input calls submit once with both values', (tester) async {
    final calls = <(String, String)>[];
    await pumpLogin(tester, onSubmit: (e, p) => calls.add((e, p)));
    await tester.enterText(field('EMAIL'), '  demo@jstack.co ');
    await tester.enterText(field('PASSWORD'), 'Demo@123');

    await tapSignIn(tester);

    expect(calls, [('demo@jstack.co', 'Demo@123')]);
  });

  testWidgets('isLoading shows the loading button and blocks a tap', (
    tester,
  ) async {
    var calls = 0;
    await pumpLogin(tester, isLoading: true, onSubmit: (_, _) => calls++);
    await tester.enterText(field('EMAIL'), 'demo@jstack.co');
    await tester.enterText(field('PASSWORD'), 'Demo@123');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tapSignIn(tester);
    await tapSignIn(tester);

    expect(calls, 0);
  });

  testWidgets('errorMessage renders in brand and nothing navigates', (
    tester,
  ) async {
    final observer = _PushRecorder();
    await pumpLogin(
      tester,
      errorMessage: 'Email or password is incorrect.',
      observer: observer,
    );
    final pushesAfterFirstFrame = observer.pushes;

    final message = tester.widget<Text>(
      find.text('Email or password is incorrect.'),
    );
    expect(message.style!.color, AppColors.brand);

    await tester.enterText(field('EMAIL'), 'demo@jstack.co');
    await tester.enterText(field('PASSWORD'), 'wrong');
    await tapSignIn(tester);
    expect(observer.pushes, pushesAfterFirstFrame);
  });

  testWidgets('demo credentials card shows the demo login', (tester) async {
    await pumpLogin(tester);

    expect(find.text('DEMO CREDENTIALS'), findsOneWidget);
    expect(find.text('demo@jstack.co'), findsOneWidget);
    expect(find.text('Demo@123'), findsOneWidget);
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    testWidgets('lays out at ${size.width}x${size.height} without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpLogin(tester, errorMessage: 'Email or password is incorrect.');
      await tapSignIn(tester); // show both field errors too

      expect(tester.takeException(), isNull);
    });
  }
}
