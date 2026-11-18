import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/login_error_message.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/transactions/presentation/models/history_view.dart';
import '../../features/transactions/presentation/models/transaction_details_view.dart';
import '../../features/transactions/presentation/screens/transaction_details_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/bloc/transaction_details_bloc.dart';
import '../../features/transactions/presentation/bloc/transactions_bloc.dart';
import '../../features/transfer/presentation/bloc/available_balance_cubit.dart';
import '../../features/transfer/presentation/bloc/transfer_bloc.dart';
import '../../features/transfer/presentation/models/confirmation_view.dart';
import '../../features/transfer/presentation/models/transfer_attempt.dart';
import '../../features/transfer/presentation/models/transfer_draft.dart';
import '../../features/transfer/presentation/models/transfer_outcome.dart';
import '../../features/transfer/presentation/screens/confirm_transfer_screen.dart';
import '../../features/transfer/presentation/screens/send_money_screen.dart';
import '../../features/transfer/presentation/screens/transfer_result_screen.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/wallet/presentation/models/dashboard_models.dart';
import '../../features/wallet/presentation/screens/dashboard_screen.dart';
import '../../features/wallet/presentation/widgets/balance_section.dart';
import '../../features/wallet/presentation/widgets/dashboard_header.dart';
import '../../features/wallet/presentation/widgets/recent_activity.dart';
import '../di/injector.dart';
import '../presentation/section.dart';
import '../widgets/transaction_row.dart';
import 'app_routes.dart';
import 'not_found_screen.dart';
import 'stream_listenable.dart';

/// Builds the app's router. Seven flat routes, one auth guard.
///
/// The guard reads [authBloc]: signed in means [AuthAuthenticated]. The
/// router re-runs it on every new auth state, so signing in, signing out and
/// an expired session all move the user.
///
/// Each data screen gets its bloc from a [BlocProvider] scoped to its route,
/// so it loads when opened and is closed when left.
GoRouter createAppRouter({required AuthBloc authBloc}) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: StreamListenable(authBloc.stream),
    redirect: (context, state) => authRedirect(
      isAuthenticated: authBloc.state is AuthAuthenticated,
      location: state.matchedLocation,
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => BlocBuilder<AuthBloc, AuthState>(
          bloc: authBloc,
          builder: (context, auth) => LoginScreen(
            onSubmit: (email, password) => authBloc.add(
              AuthLoginSubmitted(email: email, password: password),
            ),
            isLoading: auth is AuthSubmitting,
            errorMessage: switch (auth) {
              AuthLoginFailed(:final failure) => loginErrorMessage(failure),
              _ => null,
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardName,
        // The bloc lives as long as the dashboard route; opening it loads
        // all three sections at once. The screen is built once; each slot
        // has its own BlocSelector, so a section rebuilds only when its own
        // value changes (e.g. retrying the balance never rebuilds the list;
        // WalletState.copyWith keeps unchanged sections as the same object).
        builder: (context, state) => BlocProvider(
          create: (_) =>
              WalletBloc(wallet: getIt(), transactions: getIt())
                ..add(const WalletStarted()),
          child: Builder(
            builder: (context) {
              final wallet = context.read<WalletBloc>();
              return DashboardScreen(
                header:
                    BlocSelector<WalletBloc, WalletState, Section<ProfileView>>(
                      selector: (s) => s.profile,
                      builder: (context, profile) => DashboardHeader(
                        profile: profile,
                        onSignOut: () =>
                            authBloc.add(const AuthLogoutRequested()),
                      ),
                    ),
                balancePanel:
                    BlocSelector<WalletBloc, WalletState, Section<BalanceView>>(
                      selector: (s) => s.balance,
                      builder: (context, balance) => BalanceSection(
                        balance: balance,
                        onRetry: () => wallet.add(const WalletBalanceRetried()),
                      ),
                    ),
                recentActivity:
                    BlocSelector<
                      WalletBloc,
                      WalletState,
                      Section<List<TransactionRowData>>
                    >(
                      selector: (s) => s.recent,
                      builder: (context, recent) => RecentActivity(
                        recent: recent,
                        onSeeAll: () => context.push(AppRoutes.transactions),
                        onTransactionTap: (reference) =>
                            _openDetails(context, reference),
                        onRetry: () => wallet.add(const WalletRecentRetried()),
                      ),
                    ),
                onRefresh: () {
                  final refresh = WalletRefreshed();
                  wallet.add(refresh);
                  return refresh.done.future;
                },
                onSendMoney: () => context.push(AppRoutes.transfer),
                onHistory: () => context.push(AppRoutes.transactions),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.transfer,
        name: AppRoutes.transferName,
        // The request key is made here, once per attempt, and travels with
        // the draft; making it in the confirm builder would change it on
        // every rebuild (TRF-04).
        // A new attempt (and key) for every submit of the form; a retry of
        // the same attempt never comes back here.
        builder: (context, state) => BlocProvider(
          create: (_) => AvailableBalanceCubit(wallet: getIt())..load(),
          child: BlocBuilder<AvailableBalanceCubit, Section<String>>(
            builder: (context, balance) => SendMoneyScreen(
              availableBalance: balance,
              // Set when editing a transfer the backend refused.
              initialDraft: state.extra is TransferDraft
                  ? state.extra! as TransferDraft
                  : null,
              onBack: () => _back(context),
              onSubmit: (draft) => context.push(
                AppRoutes.transferConfirm,
                extra: TransferAttempt(draft: draft, requestKey: _uuid.v4()),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.transferConfirm,
        name: AppRoutes.transferConfirmName,
        // Opened directly (no attempt to review): start one on Send Money.
        redirect: (context, state) =>
            state.extra is TransferAttempt ? null : AppRoutes.transfer,
        builder: (context, state) => switch (state.extra) {
          final TransferAttempt attempt => BlocProvider(
            create: (_) => TransferBloc(repository: getIt(), attempt: attempt),
            child: BlocConsumer<TransferBloc, TransferState>(
              // Leaving is a side effect, so it happens in the listener.
              // `go`, not `push`: the finished attempt leaves the stack, so
              // back can never return to confirmation and resend.
              listenWhen: (previous, current) =>
                  current.phase == TransferPhase.succeeded ||
                  current.phase == TransferPhase.failed,
              listener: (context, transfer) =>
                  context.go(AppRoutes.transferResult, extra: transfer),
              builder: (context, transfer) => ConfirmTransferScreen(
                details: ConfirmationView.fromDraft(attempt.draft),
                requestKey: attempt.requestKey,
                isSubmitting: transfer.phase == TransferPhase.submitting,
                onBack: () => _back(context),
                onConfirm: () =>
                    context.read<TransferBloc>().add(const TransferSubmitted()),
              ),
            ),
          ),
          // Unreachable: the redirect above sends anything else away.
          _ => const NotFoundScreen(),
        },
      ),
      GoRoute(
        path: AppRoutes.transferResult,
        name: AppRoutes.transferResultName,
        // Opened directly (no finished attempt): nothing to show.
        redirect: (context, state) =>
            state.extra is TransferState ? null : AppRoutes.dashboard,
        // The finished attempt arrives as `extra` from confirmation (the hop
        // the skill file allows it). "Try again" resumes that same attempt,
        // with the same Idempotency-Key. Opened directly, there is nothing
        // to show, and the redirect above returns to the dashboard.
        builder: (context, state) => switch (state.extra) {
          final TransferState finished => BlocProvider(
            create: (_) => TransferBloc(
              repository: getIt(),
              attempt: finished.attempt,
              resumeFrom: finished,
            ),
            child: BlocBuilder<TransferBloc, TransferState>(
              builder: (context, transfer) => TransferResultScreen(
                result: transferResultView(transfer),
                isRetrying: transfer.phase == TransferPhase.submitting,
                // A fresh dashboard: it reloads the balance from the backend
                // rather than adjusting the old one (TST-04).
                onBackToDashboard: () => context.go(AppRoutes.dashboard),
                onViewTransaction: () {
                  if (transfer.result case final result?) {
                    context.goNamed(
                      AppRoutes.transactionDetailsName,
                      pathParameters: {AppRoutes.idParam: result.transactionId},
                    );
                  }
                },
                onTryAgain: () =>
                    context.read<TransferBloc>().add(const TransferSubmitted()),
                // A new attempt: the form gives it a new key on submit.
                onEditTransfer: () => context.go(
                  AppRoutes.transfer,
                  extra: transfer.attempt.draft,
                ),
              ),
            ),
          ),
          _ => const NotFoundScreen(),
        },
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: AppRoutes.transactionsName,
        builder: (context, state) => BlocProvider(
          create: (_) =>
              TransactionsBloc(repository: getIt())
                ..add(const TransactionsRequested()),
          child: BlocBuilder<TransactionsBloc, Section<List<HistoryEntry>>>(
            builder: (context, transactions) => TransactionsScreen(
              transactions: transactions,
              onBack: () => _back(context),
              onOpen: (reference) => _openDetails(context, reference),
              onRetry: () => context.read<TransactionsBloc>().add(
                const TransactionsRequested(),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactionDetails,
        name: AppRoutes.transactionDetailsName,
        // Details are fetched by the id in the path (TXN-06), never taken
        // from the list item.
        builder: (context, state) => BlocProvider(
          create: (_) => TransactionDetailsBloc(
            repository: getIt(),
            id: state.pathParameters[AppRoutes.idParam]!,
          )..add(const TransactionDetailsRequested()),
          child:
              BlocBuilder<
                TransactionDetailsBloc,
                Section<TransactionDetailsView>
              >(
                builder: (context, details) => TransactionDetailsScreen(
                  details: details,
                  onBack: () => _back(context),
                  onRetry: () => context.read<TransactionDetailsBloc>().add(
                    const TransactionDetailsRequested(),
                  ),
                ),
              ),
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
