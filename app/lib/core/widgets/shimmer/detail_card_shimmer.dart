import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../detail_card.dart';
import 'shimmer_box.dart';

/// The real [DetailCard] border and dividers with placeholder rows.
/// Put it inside a [ShimmerGroup].
class DetailCardShimmer extends StatelessWidget {
  const DetailCardShimmer({super.key, this.rowCount = 6});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      // The border is painted in front of the rows: painted behind, a
      // filled row would cover its curve at the rounded corners.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.line,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: rowCount,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) => const Padding(
          padding: DetailRow.padding,
          child: Row(
            children: [
              ShimmerLine(
                style: AppTextStyles.monoLabelTight,
                box: ShimmerBox(width: 90, height: 10),
              ),
              Spacer(),
              ShimmerLine(
                style: AppTextStyles.monoValue,
                alignment: Alignment.centerRight,
                box: ShimmerBox(width: 120, height: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
