import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 48px search box with a magnifier: "Search reference or name".
class HistorySearchField extends StatelessWidget {
  const HistorySearchField({super.key, required this.controller});

  final TextEditingController controller;

  static const double _height = 48;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(
          color: AppColors.line,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: _iconSize, color: AppColors.inkFaint),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.searchInput.copyWith(color: AppColors.ink),
              cursorColor: AppColors.ink,
              decoration: InputDecoration.collapsed(
                hintText: 'Search reference or name',
                hintStyle: AppTextStyles.searchInput.copyWith(
                  color: AppColors.inkFaint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
