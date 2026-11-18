import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../transaction_row.dart';
import 'shimmer_box.dart';

/// Placeholder for one [TransactionRow], with the same padding and line
/// heights. Render it inside a TransactionRail (so the rail line stays) and
/// a [ShimmerGroup].
class TransactionRowShimmer extends StatelessWidget {
  const TransactionRowShimmer({
    super.key,
    this.density = RailDensity.dashboard,
  });

  final RailDensity density;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: TransactionRow.paddingFor(density),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLine(
                      style: AppTextStyles.rowTitle,
                      box: FractionallySizedBox(
                        widthFactor: 0.6,
                        child: ShimmerBox(height: 11),
                      ),
                    ),
                    SizedBox(height: TransactionRow.lineGap),
                    ShimmerLine(
                      style: AppTextStyles.monoMeta,
                      box: FractionallySizedBox(
                        widthFactor: 0.38,
                        child: ShimmerBox(height: 9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerLine(
                    style: AppTextStyles.monoValueBold,
                    alignment: Alignment.centerRight,
                    box: ShimmerBox(width: 70, height: 11),
                  ),
                  SizedBox(height: TransactionRow.lineGap),
                  ShimmerLine(
                    style: AppTextStyles.monoStatus,
                    alignment: Alignment.centerRight,
                    box: ShimmerBox(width: 44, height: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
        // The dot does not sweep: a flat base-colour circle in the ring.
        const Positioned(
          left: RailDot.left,
          top: 0,
          bottom: 0,
          child: Center(child: RailDot(color: AppColors.shimmerBase)),
        ),
      ],
    );
  }
}
