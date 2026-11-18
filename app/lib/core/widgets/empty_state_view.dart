import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Bordered, centred message for a list with nothing in it.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.title, required this.message});

  final String title;
  final String message;

  static const double _titleGap = 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.s12),
        border: Border.all(
          color: AppColors.line,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.emptyTitle.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: _titleGap),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
