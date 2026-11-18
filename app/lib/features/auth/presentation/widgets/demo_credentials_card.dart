import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The demo login, shown on the login screen so reviewers can sign in.
/// These are the mock backend's published credentials, not secrets.
class DemoCredentialsCard extends StatelessWidget {
  const DemoCredentialsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.line,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEMO CREDENTIALS',
            style: AppTextStyles.monoLabel.copyWith(color: AppColors.inkFaint),
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CredentialRow(label: 'Email', value: 'demo@jstack.co'),
          const SizedBox(height: AppSpacing.s8),
          const _CredentialRow(label: 'Password', value: 'Demo@123'),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.demoLabel.copyWith(color: AppColors.inkMuted),
        ),
        Text(
          value,
          style: AppTextStyles.demoValue.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}
