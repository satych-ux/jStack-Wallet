import 'package:flutter/material.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/detail_card.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/jwallet_button.dart';
import '../../../../core/widgets/shimmer/detail_card_shimmer.dart';
import '../../../../core/widgets/shimmer/shimmer_box.dart';
import '../../../../core/widgets/status_label.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../models/transaction_details_view.dart';

/// One transaction (TXN-06, TXN-07). Details are fetched by id; until they
/// arrive the hero and card shimmer. The bar and back button never wait.
class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({
    super.key,
    this.details = const SectionLoading(),
    required this.onBack,
    required this.onRetry,
  });

  final Section<TransactionDetailsView> details;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  static const double _heroGap = 26;
  static const double _cardGap = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.screenTopAppBar,
            AppSpacing.screenHorizontal,
            AppSpacing.screenBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopBar(title: 'Transaction', onBack: onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: _heroGap,
                    bottom: AppSpacing.s20,
                  ),
                  child: switch (details) {
                    SectionLoading() => const _LoadingBody(),
                    SectionLoaded(:final data) => _LoadedBody(data),
                    SectionFailed(:final message) => ErrorStateView(
                      title: 'Could not load this transaction',
                      message: message,
                      onRetry: onRetry,
                    ),
                  },
                ),
              ),
              JWalletButton(
                label: 'Back to transactions',
                onPressed: onBack,
                variant: JWalletButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody(this.data);

  final TransactionDetailsView data;

  @override
  Widget build(BuildContext context) {
    final isDebit = data.direction == TxnDirection.debit;
    final type = isDebit ? 'DEBIT' : 'CREDIT';
    final remarks = data.remarks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _TypePill(label: type, isDebit: isDebit),
        ),
        const SizedBox(height: AppSpacing.s18),
        // Very large amounts shrink rather than overflow; the fixed-height
        // slot keeps the card from moving either way.
        SizedBox(
          height: AppTextStyles.lineHeightOf(
            context,
            AppTextStyles.amountDetail,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${isDebit ? '−' : '+'}${data.amount}',
              style: AppTextStyles.amountDetail.copyWith(color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Center(child: StatusLabel(status: data.status, large: true)),
        const SizedBox(height: TransactionDetailsScreen._cardGap),
        DetailCard(
          rows: [
            DetailRow(
              label: 'TRANSACTION ID',
              value: data.id,
              kind: DetailValueKind.monoBold,
            ),
            DetailRow(
              label: isDebit ? 'BENEFICIARY' : 'SENDER',
              value: data.name,
              kind: DetailValueKind.name,
            ),
            DetailRow(label: 'MOBILE', value: data.mobileNumber),
            DetailRow(label: 'TYPE', value: type),
            DetailRow(label: 'DATE AND TIME', value: data.dateTime),
            if (remarks != null)
              DetailRow(
                label: 'REMARKS',
                value: remarks,
                kind: DetailValueKind.text,
              ),
          ],
        ),
      ],
    );
  }
}

/// Pill, amount and status placeholders over the card shimmer, all under
/// one controller.
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const ShimmerGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The real pill outline with a shimmering label, so it is
          // exactly the loaded pill's height.
          Center(child: _TypePill.loading()),
          SizedBox(height: AppSpacing.s18),
          ShimmerLine(
            style: AppTextStyles.amountDetail,
            alignment: Alignment.center,
            box: ShimmerBox(width: 200, height: 30, radius: 6),
          ),
          SizedBox(height: AppSpacing.s10),
          ShimmerLine(
            style: AppTextStyles.monoStatusLarge,
            alignment: Alignment.center,
            box: ShimmerBox(width: 64, height: 10),
          ),
          SizedBox(height: TransactionDetailsScreen._cardGap),
          DetailCardShimmer(),
        ],
      ),
    );
  }
}

/// "● DEBIT" in a hairline pill; the dot is brand for debit, success for
/// credit.
class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.isDebit})
    : isLoading = false;

  /// Same outline; the dot and label shimmer.
  const _TypePill.loading() : label = '', isDebit = true, isLoading = true;

  final String label;
  final bool isDebit;
  final bool isLoading;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: AppSpacing.s14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: AppColors.line,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const ShimmerBox(width: _dot, height: _dot, radius: _dot / 2)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDebit ? AppColors.brand : AppColors.success,
              ),
              child: const SizedBox.square(dimension: _dot),
            ),
          const SizedBox(width: AppSpacing.s8),
          if (isLoading)
            const ShimmerLine(
              style: AppTextStyles.monoLabelTight,
              box: ShimmerBox(width: 46, height: 9),
            )
          else
            Text(
              label,
              style: AppTextStyles.monoLabelTight.copyWith(
                color: AppColors.ink,
              ),
            ),
        ],
      ),
    );
  }
}
