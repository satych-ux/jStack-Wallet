import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/presentation/failure_message.dart';
import '../../../../core/presentation/section.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/dashboard_models.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

/// Loads the dashboard: profile, balance and recent activity, as three
/// independent sections fetched in parallel. Every number shown comes from
/// the backend; nothing here does arithmetic on money.
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({required this._wallet, required this._transactions}) : super(const WalletState()) {
    // Repeated starts, refreshes or retries while one runs are dropped.
    on<WalletStarted>(_onStarted, transformer: droppable());
    on<WalletRefreshed>(_onRefreshed, transformer: droppable());
    on<WalletBalanceRetried>(_onBalanceRetried, transformer: droppable());
    on<WalletRecentRetried>(_onRecentRetried, transformer: droppable());
  }

  final WalletRepository _wallet;
  final TransactionsRepository _transactions;

  /// All three requests start before any is awaited; each section updates as
  /// soon as its own answer arrives.
  Future<void> _onStarted(WalletStarted event, Emitter<WalletState> emit) async {
    emit(const WalletState());
    await Future.wait([_loadProfile(emit), _loadBalance(emit), _loadRecent(emit)]);
  }

  /// Loaded sections stay on screen while they reload; only the refresh
  /// indicator shows progress.
  Future<void> _onRefreshed(WalletRefreshed event, Emitter<WalletState> emit) async {
    try {
      await Future.wait([
        if (state.profile is! SectionLoaded) _loadProfile(emit),
        _loadBalance(emit),
        _loadRecent(emit),
      ]);
    } finally {
      event.done.complete();
    }
  }

  Future<void> _onBalanceRetried(WalletBalanceRetried event, Emitter<WalletState> emit) async {
    emit(state.copyWith(balance: const SectionLoading()));
    await _loadBalance(emit);
  }

  Future<void> _onRecentRetried(WalletRecentRetried event, Emitter<WalletState> emit) async {
    emit(state.copyWith(recent: const SectionLoading()));
    await _loadRecent(emit);
  }

  Future<void> _loadProfile(Emitter<WalletState> emit) async {
    final section = _section(await _wallet.getProfile(), ProfileView.fromUser);
    if (section != null) emit(state.copyWith(profile: section));
  }

  Future<void> _loadBalance(Emitter<WalletState> emit) async {
    final section = _section(await _wallet.getWallet(), BalanceView.fromWallet);
    if (section != null) emit(state.copyWith(balance: section));
  }

  Future<void> _loadRecent(Emitter<WalletState> emit) async {
    final section = _section(await _transactions.getTransactions(), recentRows);
    if (section != null) emit(state.copyWith(recent: section));
  }

  /// A result as a section, or null to leave the section as it is. A 401
  /// is not a section error: the session has ended and AuthBloc is already
  /// taking the user to login.
  Section<V>? _section<T, V>(Result<T> result, V Function(T) toView) => switch (result) {
    Ok(:final value) => SectionLoaded(toView(value)),
    Err(failure: UnauthorizedFailure()) => null,
    Err(:final failure) => SectionFailed(sectionErrorMessage(failure)),
  };
}
