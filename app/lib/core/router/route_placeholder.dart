// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Stands in for a screen until its task (T3–T9) replaces the route builder.
/// Shows the route name and, for details, the parsed id.
class RoutePlaceholder extends StatelessWidget {
  const RoutePlaceholder({super.key, required this.name, this.detail});

  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: AppTextStyles.headline.copyWith(color: AppColors.ink),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                detail,
                style: AppTextStyles.monoValue.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
