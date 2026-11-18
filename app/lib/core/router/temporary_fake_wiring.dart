// TEMPORARY presentation scaffolding. Delete when the data slice lands.

/// Feeds the screens from the fake repositories so the app can be walked
/// end to end before the backend is wired. Everything here is replaced by
/// the blocs and real repositories in the data slice:
/// - [FakeData]            -> the four repositories (Dio, GetIt)
/// - the `Fake*` widgets   -> WalletBloc, TransferBloc, TransactionsBloc
/// - the `_to*` converters -> the same formatting, done from real models
///
/// No balance is computed anywhere here: every amount shown comes from a
/// fake repository response, as it will from the backend.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../features/auth/data/repositories/fake_auth_repository.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/transactions/data/repositories/fake_transactions_repository.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import '../../features/transactions/presentation/models/history_view.dart';
import '../../features/transactions/presentation/models/transaction_details_view.dart';
import '../../features/transactions/presentation/screens/transaction_details_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transfer/data/repositories/fake_transfer_repository.dart';
import '../../features/transfer/domain/entities/transfer_request.dart';
import '../../features/transfer/presentation/models/confirmation_view.dart';
import '../../features/transfer/presentation/models/transfer_attempt.dart';
import '../../features/transfer/presentation/models/transfer_draft.dart';
import '../../features/transfer/presentation/models/transfer_result_view.dart';
import '../../features/transfer/presentation/screens/confirm_transfer_screen.dart';
import '../../features/transfer/presentation/screens/send_money_screen.dart';
import '../../features/wallet/data/repositories/fake_wallet_repository.dart';
import '../../features/wallet/domain/entities/wallet.dart';
import '../../features/wallet/presentation/models/dashboard_models.dart';
import '../../features/wallet/presentation/screens/dashboard_screen.dart';
import '../presentation/section.dart';
import '../widgets/status_label.dart';
import '../widgets/transaction_row.dart';

const String _unreachable = 'Could not reach the wallet. Try again.';

/// The fake repositories, each answer delayed a little (and by different
/// amounts) so shimmer and independent section loading are visible.
class FakeData {
  const FakeData({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;

  static const _wallet = FakeWalletRepository();
  static const _transactions = FakeTransactionsRepository();
  static const _transfer = FakeTransferRepository();

  Future<T> _after<T>(double factor, Future<T> Function() load) async {
    await Future<void>.delayed(latency * factor);
    return load();
  }

  Future<ProfileView> profile() =>
      _after(0.5, () async => _toProfile(FakeAuthRepository.sampleUser));

  Future<BalanceView> balance() =>
      _after(1, () async => _toBalance(await _wallet.getWallet()));

  Future<List<Transaction>> transactions() =>
      _after(1.6, _transactions.getTransactions);

  Future<Transaction> transaction(String id) =>
      _after(1, () => _transactions.getTransaction(id));

  Future<TransferResultView> transfer(TransferAttempt attempt) =>
      _after(1.5, () async {
        final result = await _transfer.transfer(
          _toRequest(attempt.draft),
          idempotencyKey: attempt.requestKey,
        );
        return TransferSucceededView(
          amount: _rupees.format(result.amount),
          beneficiaryName: attempt.draft.beneficiaryName,
          reference: result.transactionId,
          dateTime: _dateTime.format(DateTime.now()),
          // From the transfer response, not calculated.
          updatedBalance: _rupees.format(result.availableBalance),
        );
      });
}

/// Loads a future into a [Section] field and rebuilds, unless the widget
/// has gone. With no data source the section simply stays loading.
mixin _LoadsSections<W extends StatefulWidget> on State<W> {
  Future<void> loadInto<T>(
    Future<T> Function()? load,
    void Function(Section<T> section) set, {
    String failure = _unreachable,
  }) async {
    if (load == null) return;
    try {
      final value = await load();
      if (mounted) setState(() => set(SectionLoaded(value)));
    } catch (_) {
      if (mounted) setState(() => set(SectionFailed(failure)));
    }
  }
}

class FakeDashboard extends StatefulWidget {
  const FakeDashboard({
    super.key,
    required this.data,
    required this.onSendMoney,
    required this.onHistory,
    required this.onSeeAll,
    required this.onTransactionTap,
  });

  final FakeData? data;
  final VoidCallback onSendMoney;
  final VoidCallback onHistory;
  final VoidCallback onSeeAll;
  final void Function(String reference) onTransactionTap;

  @override
  State<FakeDashboard> createState() => _FakeDashboardState();
}

class _FakeDashboardState extends State<FakeDashboard>
    with _LoadsSections<FakeDashboard> {
  Section<ProfileView> _profile = const SectionLoading();
  Section<BalanceView> _balance = const SectionLoading();
  Section<List<TransactionRowData>> _recent = const SectionLoading();

  @override
  void initState() {
    super.initState();
    loadInto(widget.data?.profile, (s) => _profile = s);
    _loadBalance();
    _loadRecent();
  }

  Future<void> _loadBalance() =>
      loadInto(widget.data?.balance, (s) => _balance = s);

  Future<void> _loadRecent() {
    final data = widget.data;
    return loadInto(
      data == null
          ? null
          : () async => _toDashboardRows(await data.transactions()),
      (s) => _recent = s,
    );
  }

  /// A refresh keeps the loaded content on screen while it reloads.
  Future<void> _refresh() => Future.wait([_loadBalance(), _loadRecent()]);

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(
      profile: _profile,
      balance: _balance,
      recent: _recent,
      onRefresh: _refresh,
      onSendMoney: widget.onSendMoney,
      onHistory: widget.onHistory,
      onSeeAll: widget.onSeeAll,
      onTransactionTap: widget.onTransactionTap,
      onRetryBalance: () {
        setState(() => _balance = const SectionLoading());
        _loadBalance();
      },
      onRetryTransactions: () {
        setState(() => _recent = const SectionLoading());
        _loadRecent();
      },
    );
  }
}

class FakeSendMoney extends StatefulWidget {
  const FakeSendMoney({
    super.key,
    required this.data,
    required this.onSubmit,
    required this.onBack,
  });

  final FakeData? data;
  final void Function(TransferDraft draft) onSubmit;
  final VoidCallback onBack;

  @override
  State<FakeSendMoney> createState() => _FakeSendMoneyState();
}

class _FakeSendMoneyState extends State<FakeSendMoney>
    with _LoadsSections<FakeSendMoney> {
  Section<String> _balance = const SectionLoading();

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    loadInto(
      data == null ? null : () async => (await data.balance()).balance,
      (s) => _balance = s,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SendMoneyScreen(
      availableBalance: _balance,
      onSubmit: widget.onSubmit,
      onBack: widget.onBack,
    );
  }
}

class FakeConfirm extends StatefulWidget {
  const FakeConfirm({
    super.key,
    required this.data,
    required this.attempt,
    required this.onBack,
    required this.onResult,
  });

  final FakeData? data;
  final TransferAttempt attempt;
  final VoidCallback onBack;
  final void Function(TransferResultView result) onResult;

  @override
  State<FakeConfirm> createState() => _FakeConfirmState();
}

class _FakeConfirmState extends State<FakeConfirm> {
  bool _submitting = false;

  Future<void> _confirm() async {
    final data = widget.data;
    if (data == null || _submitting) return;
    setState(() => _submitting = true);
    TransferResultView result;
    try {
      result = await data.transfer(widget.attempt);
    } catch (_) {
      result = TransferFailedView(
        reason: 'NOT CONFIRMED',
        explanation: 'The wallet did not answer. Try again with the same key.',
        beneficiaryName: widget.attempt.draft.beneficiaryName,
        subtitle: 'We could not confirm the transfer.',
      );
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmTransferScreen(
      details: ConfirmationView.fromDraft(widget.attempt.draft),
      requestKey: widget.attempt.requestKey,
      isSubmitting: _submitting,
      onConfirm: _confirm,
      onBack: widget.onBack,
    );
  }
}

class FakeHistory extends StatefulWidget {
  const FakeHistory({
    super.key,
    required this.data,
    required this.onBack,
    required this.onOpen,
  });

  final FakeData? data;
  final VoidCallback onBack;
  final void Function(String reference) onOpen;

  @override
  State<FakeHistory> createState() => _FakeHistoryState();
}

class _FakeHistoryState extends State<FakeHistory>
    with _LoadsSections<FakeHistory> {
  Section<List<HistoryEntry>> _entries = const SectionLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() {
    final data = widget.data;
    return loadInto(
      data == null
          ? null
          : () async => [
              for (final t in await data.transactions()) _toEntry(t),
            ],
      (s) => _entries = s,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransactionsScreen(
      transactions: _entries,
      onBack: widget.onBack,
      onOpen: widget.onOpen,
      onRetry: () {
        setState(() => _entries = const SectionLoading());
        _load();
      },
    );
  }
}

class FakeDetails extends StatefulWidget {
  const FakeDetails({
    super.key,
    required this.data,
    required this.id,
    required this.onBack,
  });

  final FakeData? data;
  final String id;
  final VoidCallback onBack;

  @override
  State<FakeDetails> createState() => _FakeDetailsState();
}

class _FakeDetailsState extends State<FakeDetails>
    with _LoadsSections<FakeDetails> {
  Section<TransactionDetailsView> _details = const SectionLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() {
    final data = widget.data;
    return loadInto(
      data == null
          ? null
          : () async => _toDetails(await data.transaction(widget.id)),
      (s) => _details = s,
      failure: 'This transaction does not exist.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransactionDetailsScreen(
      details: _details,
      onBack: widget.onBack,
      onRetry: () {
        setState(() => _details = const SectionLoading());
        _load();
      },
    );
  }
}

// Converters: stub entities -> display-ready view values.

final NumberFormat _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);
final NumberFormat _plain = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '',
  decimalDigits: 2,
);
final DateFormat _shortDate = DateFormat('d MMM');
final DateFormat _dateTime = DateFormat('d MMM y, HH:mm');

ProfileView _toProfile(User user) {
  final initials = user.name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
  return ProfileView(name: user.name, initials: initials);
}

BalanceView _toBalance(Wallet wallet) => BalanceView(
  balance: _rupees.format(wallet.availableBalance),
  walletId: wallet.walletId,
  maskedAccount: wallet.maskedAccountNumber,
);

TxnDirection _direction(TransactionType type) => switch (type) {
  TransactionType.debit => TxnDirection.debit,
  TransactionType.credit => TxnDirection.credit,
};

StatusKind _status(TransactionStatus status) => switch (status) {
  TransactionStatus.success => StatusKind.success,
  TransactionStatus.pending => StatusKind.pending,
  TransactionStatus.failed => StatusKind.failed,
};

List<TransactionRowData> _toDashboardRows(List<Transaction> transactions) => [
  for (final t in transactions)
    TransactionRowData(
      name: t.name,
      reference: t.id,
      metaLabel: _shortDate.format(t.createdAt),
      amount: _plain.format(t.amount).trim(),
      direction: _direction(t.type),
      status: _status(t.status),
    ),
];

HistoryEntry _toEntry(Transaction t) => HistoryEntry(
  reference: t.id,
  name: t.name,
  amount: _plain.format(t.amount).trim(),
  direction: _direction(t.type),
  status: _status(t.status),
  createdAt: t.createdAt,
);

TransactionDetailsView _toDetails(Transaction t) => TransactionDetailsView(
  id: t.id,
  direction: _direction(t.type),
  status: _status(t.status),
  amount: _rupees.format(t.amount),
  name: t.name,
  mobileNumber: '+91 ${t.mobileNumber}',
  dateTime: _dateTime.format(t.createdAt),
  remarks: t.remarks,
);

TransferRequest _toRequest(TransferDraft draft) => TransferRequest(
  beneficiaryName: draft.beneficiaryName,
  mobileNumber: draft.mobileNumber,
  amount: double.parse(draft.amount),
  remarks: draft.remarks,
);
