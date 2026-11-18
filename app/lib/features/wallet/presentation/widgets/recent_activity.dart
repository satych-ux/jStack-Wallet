import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/shimmer/shimmer_box.dart';
import '../../../../core/widgets/shimmer/transaction_row_shimmer.dart';
import '../../../../core/widgets/transaction_rail.dart';
import '../../../../core/widgets/transaction_row.dart';

/// "RECENT ACTIVITY | See all" and the latest transactions on the rail
/// (WAL-04). Shows at most [maxRows]; shimmers [maxRows] rows while loading.
class RecentActivity extends StatelessWidget {
  const RecentActivity({
    super.key,
    required this.recent,
    required this.onSeeAll,
    required this.onTransactionTap,
    required this.onRetry,
  });

  final Section<List<TransactionRowData>> recent;
  final VoidCallback onSeeAll;
  final void Function(String reference) onTransactionTap;
  final VoidCallback onRetry;

  static const int maxRows = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 44px tall so "See all" has a full touch target; the gaps around
        // it in the screen are reduced by the same amount.
        SizedBox(
          height: AppSpacing.minTouchTarget,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'RECENT ACTIVITY',
                  style: AppTextStyles.monoLabel.copyWith(
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'See all',
                      style: AppTextStyles.link.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        switch (recent) {
          SectionLoading() => ShimmerGroup(
            child: TransactionRail(
              itemCount: maxRows,
              itemBuilder: (context, index) => const TransactionRowShimmer(),
            ),
          ),
          SectionLoaded(:final data) when data.isEmpty => const EmptyStateView(
            title: 'No transactions yet',
            message: 'Your first transfer will appear here.',
          ),
          SectionLoaded(:final data) => TransactionRail(
            itemCount: math.min(data.length, maxRows),
            itemBuilder: (context, index) => TransactionRow(
              data: data[index],
              onTap: () => onTransactionTap(data[index].reference),
            ),
          ),
          SectionFailed(:final message) => ErrorStateView(
            title: 'Could not load activity',
            message: message,
            onRetry: onRetry,
          ),
        },
      ],
    );
  }
}
