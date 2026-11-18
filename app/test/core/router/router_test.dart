import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:j_stack_flutter_app/core/router/app_router.dart';
import 'package:j_stack_flutter_app/core/router/app_routes.dart';
import 'package:j_stack_flutter_app/core/router/not_found_screen.dart';
import 'package:j_stack_flutter_app/features/transactions/presentation/screens/transaction_details_screen.dart';

/// Builds the real router with a controllable auth flag and pumps it.
Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  required bool authenticated,
}) async {
  final auth = ValueNotifier(authenticated);
  final router = createAppRouter(isAuthenticated: auth);
  addTearDown(router.dispose);
  addTearDown(auth.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await settle(tester);
  return router;
}

/// Lets the route change and its page transition finish. Not pumpAndSettle:
/// the dashboard shimmers until data arrives, so it never "settles".
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

String currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('unauthenticated start resolves to /login', (tester) async {
    final router = await pumpRouter(tester, authenticated: false);
    expect(currentPath(router), AppRoutes.login);
  });

  testWidgets('authenticated start resolves to /dashboard', (tester) async {
    final router = await pumpRouter(tester, authenticated: true);
    expect(currentPath(router), AppRoutes.dashboard);
  });

  testWidgets('authenticated navigation to /login redirects to /dashboard', (
    tester,
  ) async {
    final router = await pumpRouter(tester, authenticated: true);

    router.go(AppRoutes.login);
    await settle(tester);

    expect(currentPath(router), AppRoutes.dashboard);
  });

  testWidgets('unauthenticated navigation to a protected route goes to login', (
    tester,
  ) async {
    final router = await pumpRouter(tester, authenticated: false);

    router.go(AppRoutes.transfer);
    await settle(tester);

    expect(currentPath(router), AppRoutes.login);
  });

  testWidgets('the guard re-runs when the auth flag changes', (tester) async {
    final auth = ValueNotifier(false);
    final router = createAppRouter(isAuthenticated: auth);
    addTearDown(router.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await settle(tester);
    expect(currentPath(router), AppRoutes.login);

    auth.value = true;
    await settle(tester);
    expect(currentPath(router), AppRoutes.dashboard);

    auth.value = false;
    await settle(tester);
    expect(currentPath(router), AppRoutes.login);
  });

  testWidgets('/transactions/TXN10001 parses id as TXN10001', (tester) async {
    final router = await pumpRouter(tester, authenticated: true);

    router.goNamed(
      AppRoutes.transactionDetailsName,
      pathParameters: {AppRoutes.idParam: 'TXN10001'},
    );
    await settle(tester);

    expect(currentPath(router), '/transactions/TXN10001');
    expect(
      router.routerDelegate.currentConfiguration.pathParameters[AppRoutes
          .idParam],
      'TXN10001',
    );
    expect(find.byType(TransactionDetailsScreen), findsOneWidget);
  });

  testWidgets('an unknown path renders the error page', (tester) async {
    final router = await pumpRouter(tester, authenticated: true);

    router.go('/no-such-page');
    await settle(tester);

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets('every route in AppRoutes is reachable', (tester) async {
    final router = await pumpRouter(tester, authenticated: true);

    for (final route in AppRoutes.all) {
      // Login is only reachable signed out; the redirect test covers it.
      if (route.path == AppRoutes.login) continue;
      final location = route.path.replaceFirst(
        ':${AppRoutes.idParam}',
        'TXN10001',
      );
      router.go(location);
      await settle(tester);

      expect(currentPath(router), location, reason: route.name);
      expect(find.byType(NotFoundScreen), findsNothing, reason: route.name);
    }
  });

  testWidgets('login is reachable when signed out', (tester) async {
    final router = await pumpRouter(tester, authenticated: false);
    expect(find.byType(NotFoundScreen), findsNothing);
    expect(currentPath(router), AppRoutes.login);
  });

  test('AppRoutes.all lists every route exactly once', () {
    expect(AppRoutes.all, hasLength(7));
    expect(AppRoutes.all.map((r) => r.path).toSet(), hasLength(7));
    expect(AppRoutes.all.map((r) => r.name).toSet(), hasLength(7));
  });
}
