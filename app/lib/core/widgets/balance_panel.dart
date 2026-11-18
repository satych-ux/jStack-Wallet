import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The dark balance card. Every value arrives formatted from the caller;
/// the panel only lays it out. The balance is whatever the backend said.
class BalancePanel extends StatelessWidget {
  const BalancePanel({
    super.key,
    required this.balance,
    required this.walletId,
    required this.maskedAccount,
  });

  /// e.g. `₹25,450.75`.
  final String balance;
  final String walletId;
  final String maskedAccount;

  // Geometry shared with BalancePanelShimmer so the two are the same height.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(22, 22, 22, 18);
  static const BoxDecoration decoration = BoxDecoration(
    color: AppColors.ink,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusPanel)),
  );
  static const double balanceGap = AppSpacing.s12;
  static const double dividerGap = AppSpacing.s18;
  static const double fieldsGap = AppSpacing.s14;
  static const double fieldLabelGap = 6;

  static const double _barWidth = 2;
  static const double _barHeight = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ColoredBox(
                color: AppColors.brand,
                child: SizedBox(width: _barWidth, height: _barHeight),
              ),
              const SizedBox(width: AppSpacing.s10),
              Text(
                'AVAILABLE BALANCE',
                style: AppTextStyles.monoLabel.copyWith(
                  color: AppColors.onDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: balanceGap),
          // A very large balance scales down instead of overflowing; the
          // fixed-height slot keeps the panel the same height either way.
          SizedBox(
            height: AppTextStyles.lineHeightOf(context, AppTextStyles.balance),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                balance,
                style: AppTextStyles.balance.copyWith(color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(height: dividerGap),
          const ColoredBox(
            color: AppColors.darkDivider,
            child: SizedBox(height: 1, width: double.infinity),
          ),
          const SizedBox(height: fieldsGap),
          Row(
            children: [
              Expanded(
                child: _PanelField(
                  label: 'WALLET ID',
                  value: walletId,
                  alignEnd: false,
                ),
              ),
              Expanded(
                child: _PanelField(
                  label: 'ACCOUNT',
                  value: maskedAccount,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelField extends StatelessWidget {
  const _PanelField({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.panelLabel.copyWith(
            color: AppColors.onDarkLabel,
          ),
        ),
        const SizedBox(height: BalancePanel.fieldLabelGap),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.panelValue.copyWith(
            color: AppColors.onDarkValue,
          ),
        ),
      ],
    );
  }
}
