import 'package:flutter/widgets.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer/shimmer_box.dart';
import '../models/dashboard_models.dart';

/// "WELCOME BACK", the user's name and an initials avatar. The name and
/// avatar shimmer while the profile loads; on failure the name slot stays
/// blank (the header keeps its height) rather than showing an error here.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.profile});

  final Section<ProfileView> profile;

  static const double _nameGap = 5;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: AppTextStyles.monoLabel.copyWith(
                  color: AppColors.inkFaint,
                ),
              ),
              const SizedBox(height: _nameGap),
              switch (profile) {
                SectionLoading() => const ShimmerLine(
                  style: AppTextStyles.titleName,
                  box: ShimmerBox(width: 140, height: 16),
                ),
                SectionLoaded(:final data) => Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleName.copyWith(color: AppColors.ink),
                ),
                SectionFailed() => SizedBox(
                  height: AppTextStyles.lineHeightOf(
                    context,
                    AppTextStyles.titleName,
                  ),
                ),
              },
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        switch (profile) {
          SectionLoading() => const ShimmerBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            radius: AppSpacing.minTouchTarget / 2,
          ),
          SectionLoaded(:final data) => _Avatar(initials: data.initials),
          SectionFailed() => const _Avatar(initials: ''),
        },
      ],
    );

    // One shimmer controller for the whole header while it loads.
    return profile is SectionLoading ? ShimmerGroup(child: row) : row;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.minTouchTarget,
      height: AppSpacing.minTouchTarget,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppTextStyles.rowTitle.copyWith(color: AppColors.white),
      ),
    );
  }
}
