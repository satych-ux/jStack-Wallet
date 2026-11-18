import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../balance_panel.dart';
import 'shimmer_box.dart';

/// The real ink panel with placeholder lines in place of the text. Uses
/// [BalancePanel]'s own padding and gaps, so the two are the same height.
/// Put it inside a [ShimmerGroup].
class BalancePanelShimmer extends StatelessWidget {
  const BalancePanelShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: BalancePanel.padding,
      decoration: BalancePanel.decoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLine(
            style: AppTextStyles.monoLabel,
            box: ShimmerBox(width: 120, height: 11, onDark: true),
          ),
          SizedBox(height: BalancePanel.balanceGap),
          ShimmerLine(
            style: AppTextStyles.balance,
            box: ShimmerBox(width: 190, height: 28, radius: 6, onDark: true),
          ),
          SizedBox(height: BalancePanel.dividerGap),
          ColoredBox(
            color: AppColors.darkDivider,
            child: SizedBox(height: 1, width: double.infinity),
          ),
          SizedBox(height: BalancePanel.fieldsGap),
          Row(
            children: [
              Expanded(child: _FieldShimmer(alignment: Alignment.centerLeft)),
              Expanded(child: _FieldShimmer(alignment: Alignment.centerRight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldShimmer extends StatelessWidget {
  const _FieldShimmer({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerLine(
          style: AppTextStyles.panelLabel,
          alignment: alignment,
          box: const ShimmerBox(width: 70, height: 9, onDark: true),
        ),
        const SizedBox(height: BalancePanel.fieldLabelGap),
        ShimmerLine(
          style: AppTextStyles.panelValue,
          alignment: alignment,
          box: const ShimmerBox(width: 96, height: 12, onDark: true),
        ),
      ],
    );
  }
}
