import 'package:flutter/material.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/balance_panel.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/quick_action_card.dart';
import '../../../../core/widgets/shimmer/balance_panel_shimmer.dart';
import '../../../../core/widgets/shimmer/shimmer_box.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../models/dashboard_models.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/recent_activity.dart';

/// Wallet dashboard (WAL-01..06).
///
/// Profile, balance and recent activity are three [Section]s that load
/// independently: each shimmers, loads or fails on its own. Every section
/// defaults to loading, so the screen renders standalone with no data.
/// Quick actions never wait for data.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.profile = const SectionLoading(),
    this.balance = const SectionLoading(),
    this.recent = const SectionLoading(),
    required this.onRefresh,
    required this.onSendMoney,
    required this.onHistory,
    required this.onSeeAll,
    required this.onTransactionTap,
    required this.onRetryBalance,
    required this.onRetryTransactions,
  });

  final Section<ProfileView> profile;
  final Section<BalanceView> balance;
  final Section<List<TransactionRowData>> recent;

  /// Pull-to-refresh. The caller keeps the sections loaded while this runs,
  /// so content stays on screen; the indicator shows progress.
  final Future<void> Function() onRefresh;
  final VoidCallback onSendMoney;
  final VoidCallback onHistory;
  final VoidCallback onSeeAll;
  final void Function(String reference) onTransactionTap;
  final VoidCallback onRetryBalance;
  final VoidCallback onRetryTransactions;

  static const double _quickActionGap = 10;

  /// Gaps around the 44px "RECENT ACTIVITY" row, reduced from DESIGN's 26
  /// and 14 by the row's extra touch-target height (about 14 each side).
  static const double _activityTopGap = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: onRefresh,
          child: CustomScrollView(
            // Pull-to-refresh must work even when content fits the screen.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.screenTopDashboard,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    DashboardHeader(profile: profile),
                    const SizedBox(height: AppSpacing.s22),
                    switch (balance) {
                      SectionLoading() => const ShimmerGroup(
                        child: BalancePanelShimmer(),
                      ),
                      SectionLoaded(:final data) => BalancePanel(
                        balance: data.balance,
                        walletId: data.walletId,
                        maskedAccount: data.maskedAccount,
                      ),
                      SectionFailed(:final message) => ErrorStateView(
                        title: 'Could not load your balance',
                        message: message,
                        onRetry: onRetryBalance,
                      ),
                    },
                    const SizedBox(height: AppSpacing.s18),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.north_east,
                            label: 'Send money',
                            onTap: onSendMoney,
                          ),
                        ),
                        const SizedBox(width: _quickActionGap),
                        const Expanded(
                          child: QuickActionCard(
                            icon: Icons.add,
                            label: 'Add money',
                            isComingSoon: true,
                          ),
                        ),
                        const SizedBox(width: _quickActionGap),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.notes,
                            label: 'History',
                            onTap: onHistory,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _activityTopGap),
                    RecentActivity(
                      recent: recent,
                      onSeeAll: onSeeAll,
                      onTransactionTap: onTransactionTap,
                      onRetry: onRetryTransactions,
                    ),
                  ],
                ),
              ),
              // Pushes the hint to the bottom on tall screens.
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.s26,
                    AppSpacing.screenHorizontal,
                    AppSpacing.screenBottom,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _RefreshHint(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshHint extends StatelessWidget {
  const _RefreshHint();

  static const double _iconSize = 13;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.refresh, size: _iconSize, color: AppColors.inkFaint),
        const SizedBox(width: AppSpacing.s8),
        Text(
          'Pull to refresh',
          style: AppTextStyles.caption.copyWith(color: AppColors.inkFaint),
        ),
      ],
    );
  }
}
