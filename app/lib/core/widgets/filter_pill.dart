import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// All / Credit / Debit filter. 36px tall, with 4px of invisible padding
/// above and below so the tap target reaches 44px.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: (AppSpacing.minTouchTarget - AppSpacing.pillHeight) / 2,
          ),
          child: Container(
            height: AppSpacing.pillHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            decoration: BoxDecoration(
              color: selected ? AppColors.ink : AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: selected ? AppColors.ink : AppColors.line,
                width: AppSpacing.borderWidth,
              ),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppTextStyles.pillLabel.copyWith(
                  color: selected ? AppColors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
