import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/transfer/presentation/models/transfer_attempt.dart';
import '../../features/transfer/presentation/models/transfer_result_view.dart';
import '../../features/transfer/presentation/screens/transfer_result_screen.dart';
import 'app_routes.dart';
import 'not_found_screen.dart';
import 'route_placeholder.dart';
import 'temporary_fake_wiring.dart';

/// Builds the app's router. Seven flat routes, one auth guard.
///
/// [isAuthenticated] is the guard's only input. It is also the router's
/// `refreshListenable`, so signing in or out re-runs the guard and moves the
/// user. Today a test or `main` passes a ValueNotifier; the auth slice will
/// pass a listenable driven by AuthBloc.
///
/// [onLoginSubmitted] receives a validated email and password from the login
/// screen. The auth slice points it at AuthBloc.
///
/// [fakeData] (TEMPORARY) feeds the screens from the fake repositories.
/// Without it every data section stays loading. The data slice removes it
/// and the `Fake*` wrappers, and builds each screen from its bloc instead.
GoRouter createAppRouter({
  required ValueListenable<bool> isAuthenticated,
  void Function(String email, String password)? onLoginSubmitted,
  FakeData? fakeData,
}) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: isAuthenticated,
    redirect: (context, state) => authRedirect(
      isAuthenticated: isAuthenticated.value,
      location: state.matchedLocation,
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        // The auth slice also passes isLoading / errorMessage from AuthBloc.
        builder: (context, state) =>
            LoginScreen(onSubmit: onLoginSubmitted ?? (_, _) {}),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardName,
        builder: (context, state) => FakeDashboard(
          data: fakeData,
          onSendMoney: () => context.push(AppRoutes.transfer),
          onHistory: () => context.push(AppRoutes.transactions),
          onSeeAll: () => context.push(AppRoutes.transactions),
          onTransactionTap: (reference) => _openDetails(context, reference),
        ),
      ),
      GoRoute(
        path: AppRoutes.transfer,
        name: AppRoutes.transferName,
        // The request key is made here, once per attempt, and travels with
        // the draft; making it in the confirm builder would change it on
        // every rebuild (TRF-04).
        builder: (context, state) => FakeSendMoney(
          data: fakeData,
          onBack: () => _back(context),
          onSubmit: (draft) => context.push(
            AppRoutes.transferConfirm,
            extra: TransferAttempt(draft: draft, requestKey: _uuid.v4()),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.transferConfirm,
        name: AppRoutes.transferConfirmName,
        // Opened directly there is no attempt to review.
        builder: (context, state) => switch (state.extra) {
          final TransferAttempt attempt => FakeConfirm(
            data: fakeData,
            attempt: attempt,
            onBack: () => _back(context),
            // `go`, not `push`: the finished attempt leaves the stack, so
            // back cannot return to confirmation and resend.
            onResult: (result) =>
                context.go(AppRoutes.transferResult, extra: result),
          ),
          _ => const RoutePlaceholder(name: AppRoutes.transferConfirmName),
        },
      ),
      GoRoute(
        path: AppRoutes.transferResult,
        name: AppRoutes.transferResultName,
        // The outcome arrives as `extra` from confirmation (the hop the
        // skill file allows it). Opened directly, there is nothing to show.
        builder: (context, state) => switch (state.extra) {
          final TransferResultView result => TransferResultScreen(
            result: result,
            onBackToDashboard: () => context.go(AppRoutes.dashboard),
            onViewTransaction: () {
              if (result case TransferSucceededView(:final reference)) {
                context.goNamed(
                  AppRoutes.transactionDetailsName,
                  pathParameters: {AppRoutes.idParam: reference},
                );
              }
            },
            // TransferBloc retries with the same key in the data slice.
            onTryAgain: () {},
          ),
          _ => const RoutePlaceholder(name: AppRoutes.transferResultName),
        },
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: AppRoutes.transactionsName,
        builder: (context, state) => FakeHistory(
          data: fakeData,
          onBack: () => _back(context),
          onOpen: (reference) => _openDetails(context, reference),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactionDetails,
        name: AppRoutes.transactionDetailsName,
        // Details are fetched by the id in the path (TXN-06).
        builder: (context, state) => FakeDetails(
          data: fakeData,
          id: state.pathParameters[AppRoutes.idParam]!,
          onBack: () => _back(context),
        ),
      ),
    ],
  );
}

const Uuid _uuid = Uuid();

void _openDetails(BuildContext context, String reference) {
  context.pushNamed(
    AppRoutes.transactionDetailsName,
    pathParameters: {AppRoutes.idParam: reference},
  );
}

/// Back from a pushed screen; falls back to the dashboard when the screen
/// was opened directly (nothing to pop).
void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.dashboard);
  }
}

/// The auth guard, as a pure function so it is easy to read and test.
/// Signed out: everything except login goes to login.
/// Signed in: login goes to the dashboard. Otherwise, stay.
String? authRedirect({
  required bool isAuthenticated,
  required String location,
}) {
  final atLogin = location == AppRoutes.login;
  if (!isAuthenticated) return atLogin ? null : AppRoutes.login;
  return atLogin ? AppRoutes.dashboard : null;
}
