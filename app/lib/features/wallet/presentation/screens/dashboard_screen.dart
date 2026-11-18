import 'package:flutter/material.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/quick_action_card.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../models/dashboard_models.dart';
import '../widgets/balance_section.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/recent_activity.dart';

/// Wallet dashboard (WAL-01..06).
///
/// Profile, balance and recent activity load independently, so the screen
/// takes each as its own slot widget. The app builds every slot inside its
/// own `BlocSelector`: a balance update rebuilds the balance panel only,
/// never the header, the transaction list or this scaffold.
/// [DashboardScreen.fromSections] builds the same slots from plain sections.
/// Quick actions never wait for data.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.header,
    required this.balancePanel,
    required this.recentActivity,
    required this.onRefresh,
    required this.onSendMoney,
    required this.onHistory,
  });

  /// The slots built straight from sections, for when nothing needs
  /// selective rebuilds (tests, previews). Every section defaults to
  /// loading, so the screen renders standalone with no data.
  factory DashboardScreen.fromSections({
    Key? key,
    Section<ProfileView> profile = const SectionLoading(),
    Section<BalanceView> balance = const SectionLoading(),
    Section<List<TransactionRowData>> recent = const SectionLoading(),
    required Future<void> Function() onRefresh,
    required VoidCallback onSendMoney,
    required VoidCallback onHistory,
    required VoidCallback onSeeAll,
    required void Function(String reference) onTransactionTap,
    required VoidCallback onRetryBalance,
    required VoidCallback onRetryTransactions,
    VoidCallback? onSignOut,
  }) => DashboardScreen(
    key: key,
    header: DashboardHeader(profile: profile, onSignOut: onSignOut),
    balancePanel: BalanceSection(balance: balance, onRetry: onRetryBalance),
    recentActivity: RecentActivity(
      recent: recent,
      onSeeAll: onSeeAll,
      onTransactionTap: onTransactionTap,
      onRetry: onRetryTransactions,
    ),
    onRefresh: onRefresh,
    onSendMoney: onSendMoney,
    onHistory: onHistory,
  );

  /// Usually a [DashboardHeader].
  final Widget header;

  /// Usually a [BalanceSection].
  final Widget balancePanel;

  /// Usually a [RecentActivity].
  final Widget recentActivity;

  /// Pull-to-refresh. The caller keeps the sections loaded while this runs,
  /// so content stays on screen; the indicator shows progress.
  final Future<void> Function() onRefresh;
  final VoidCallback onSendMoney;
  final VoidCallback onHistory;

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
                    header,
                    const SizedBox(height: AppSpacing.s22),
                    balancePanel,
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
                    recentActivity,
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
