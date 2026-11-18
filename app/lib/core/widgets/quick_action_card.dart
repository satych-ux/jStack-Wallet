import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 84px tile with an icon over a label. When [isComingSoon] is true it is
/// greyed out, shows a SOON pill and ignores taps.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isComingSoon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isComingSoon;

  static const double _height = 84;
  static const double _iconSize = 22;
  static const double _iconGap = 9;
  static const double _pillInset = 8;

  @override
  Widget build(BuildContext context) {
    final color = isComingSoon ? AppColors.inkFaint : AppColors.ink;
    return Semantics(
      button: true,
      enabled: !isComingSoon,
      child: GestureDetector(
        onTap: isComingSoon ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusQuickAction),
            border: Border.all(
              color: AppColors.line,
              width: AppSpacing.borderWidth,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: _iconSize, color: color),
                    const SizedBox(height: _iconGap),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.quickActionLabel.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isComingSoon)
                const Positioned(
                  top: _pillInset,
                  right: _pillInset,
                  child: _SoonPill(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoonPill extends StatelessWidget {
  const _SoonPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: AppColors.line,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Text(
        'SOON',
        style: AppTextStyles.soonPill.copyWith(color: AppColors.inkFaint),
      ),
    );
  }
}
