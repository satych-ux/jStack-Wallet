part of 'wallet_bloc.dart';

/// The dashboard's three sections, each loading, loaded or failed on its
/// own (WAL-06). One state, updated by [copyWith], so a section changing
/// never resets the others.
class WalletState {
  const WalletState({
    this.profile = const SectionLoading(),
    this.balance = const SectionLoading(),
    this.recent = const SectionLoading(),
  });

  final Section<ProfileView> profile;
  final Section<BalanceView> balance;
  final Section<List<TransactionRowData>> recent;

  WalletState copyWith({
    Section<ProfileView>? profile,
    Section<BalanceView>? balance,
    Section<List<TransactionRowData>>? recent,
  }) => WalletState(
    profile: profile ?? this.profile,
    balance: balance ?? this.balance,
    recent: recent ?? this.recent,
  );
}
