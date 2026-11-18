import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 44px bar: back chevron and title. Shifted 10px left so the chevron's
/// glyph, not its 44px touch box, lines up with the 20px screen padding.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  static const double _shift = -10;
  static const double _chevronSize = 22;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: Transform.translate(
        offset: const Offset(_shift, 0),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
              ),
              icon: const Icon(
                Icons.chevron_left,
                size: _chevronSize,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleAppBar.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
