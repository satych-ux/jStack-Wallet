import 'package:flutter/widgets.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer/shimmer_box.dart';

/// "AVAILABLE ₹25,450.75" on a recessed strip. Information only: the form
/// never uses it to block a transfer. The amount shimmers while loading
/// and reads "Unavailable" if the balance could not be fetched.
class BalanceStrip extends StatelessWidget {
  const BalanceStrip({super.key, required this.balance});

  final Section<String> balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s14,
        horizontal: AppSpacing.s16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.s12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'AVAILABLE',
              style: AppTextStyles.monoLabel.copyWith(
                color: AppColors.inkFaint,
              ),
            ),
          ),
          switch (balance) {
            SectionLoading() => const ShimmerGroup(
              child: ShimmerLine(
                style: AppTextStyles.stripAmount,
                alignment: Alignment.centerRight,
                box: ShimmerBox(width: 90, height: 12),
              ),
            ),
            SectionLoaded(:final data) => Text(
              data,
              style: AppTextStyles.stripAmount.copyWith(color: AppColors.ink),
            ),
            SectionFailed() => Text(
              'Unavailable',
              style: AppTextStyles.caption.copyWith(color: AppColors.inkFaint),
            ),
          },
        ],
      ),
    );
  }
}
