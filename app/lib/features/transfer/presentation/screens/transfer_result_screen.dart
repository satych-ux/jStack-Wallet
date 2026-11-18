import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/detail_card.dart';
import '../../../../core/widgets/jwallet_button.dart';
import '../models/transfer_result_view.dart';

/// Transfer outcome (TRF-06, TRF-07). One screen for both: [result] is a
/// success or a failure, and every part of the layout switches on it.
///
/// Back (system gesture) goes to the dashboard: returning to confirmation
/// after a finished attempt would invite a duplicate send.
class TransferResultScreen extends StatelessWidget {
  const TransferResultScreen({
    super.key,
    required this.result,
    this.isRetrying = false,
    required this.onBackToDashboard,
    required this.onViewTransaction,
    required this.onTryAgain,
    required this.onEditTransfer,
  });

  final TransferResultView result;

  /// Failure only: a retry (same request key) is in flight.
  final bool isRetrying;
  final VoidCallback onBackToDashboard;

  /// Success only.
  final VoidCallback onViewTransaction;

  /// Failure only, when [TransferFailedView.canRetry]. Retries with the
  /// same Idempotency-Key.
  final VoidCallback onTryAgain;

  /// Failure only, when retrying can't help (e.g. insufficient balance):
  /// back to the form with the details filled in. Submitting it is a new
  /// transfer with a new key.
  final VoidCallback onEditTransfer;

  static const double _haloSize = 76;
  static const double _iconSize = 32;
  static const double _iconGap = 22;
  static const double _cardGap = 34;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final isSuccess = result is TransferSucceededView;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBackToDashboard();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              0,
              AppSpacing.screenHorizontal,
              AppSpacing.screenBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.screenTopResult,
                      bottom: AppSpacing.s20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: _haloSize,
                            height: _haloSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSuccess
                                  ? AppColors.successTint
                                  : AppColors.brandTint,
                            ),
                            child: Icon(
                              isSuccess ? Icons.check : Icons.priority_high,
                              size: _iconSize,
                              color: isSuccess
                                  ? AppColors.success
                                  : AppColors.brand,
                            ),
                          ),
                        ),
                        const SizedBox(height: _iconGap),
                        Text(
                          isSuccess
                              ? 'Transfer successful'
                              : 'Transfer not completed',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s10),
                        switch (result) {
                          TransferSucceededView() => _SuccessSummary(result),
                          TransferFailedView(:final subtitle) => Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        },
                        const SizedBox(height: _cardGap),
                        switch (result) {
                          TransferSucceededView() => _successCard(result),
                          TransferFailedView() => _failureCard(result),
                        },
                        const SizedBox(height: AppSpacing.s18),
                        Text(
                          switch (result) {
                            TransferSucceededView() =>
                              'The balance above came back from the transfer '
                                  'response. The dashboard refetches it rather '
                                  'than calculating it locally.',
                            TransferFailedView(canRetry: true) =>
                              'Retrying reuses the same request key, so a '
                                  'transfer that actually succeeded on the '
                                  'server will return its original result '
                                  'instead of debiting again.',
                            TransferFailedView() =>
                              'Edit the transfer to change it. Sending it '
                                  'again is a new request with a new key.',
                          },
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._buttons(isSuccess),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buttons(bool isSuccess) {
    final result = this.result;
    if (result is TransferFailedView && !result.canRetry) {
      return [
        JWalletButton(label: 'Edit transfer', onPressed: onEditTransfer),
        const SizedBox(height: AppSpacing.s10),
        JWalletButton(
          label: 'Back to dashboard',
          onPressed: onBackToDashboard,
          variant: JWalletButtonVariant.secondary,
        ),
      ];
    }
    if (isSuccess) {
      return [
        JWalletButton(label: 'Back to dashboard', onPressed: onBackToDashboard),
        const SizedBox(height: AppSpacing.s10),
        JWalletButton(
          label: 'View transaction',
          onPressed: onViewTransaction,
          variant: JWalletButtonVariant.secondary,
        ),
      ];
    }
    return [
      JWalletButton(
        label: isRetrying ? 'Retrying' : 'Try again',
        onPressed: onTryAgain,
        variant: isRetrying
            ? JWalletButtonVariant.loading
            : JWalletButtonVariant.primary,
      ),
      const SizedBox(height: AppSpacing.s10),
      JWalletButton(
        label: 'Back to dashboard',
        onPressed: onBackToDashboard,
        variant: JWalletButtonVariant.secondary,
      ),
    ];
  }

  static Widget _successCard(TransferSucceededView result) {
    return DetailCard(
      rows: [
        DetailRow(label: 'REFERENCE', value: result.reference),
        DetailRow(label: 'DATE AND TIME', value: result.dateTime),
        const DetailRow(
          label: 'STATUS',
          value: 'SUCCESS',
          kind: DetailValueKind.status,
          valueColor: AppColors.success,
        ),
        DetailRow(
          label: 'UPDATED BALANCE',
          value: result.updatedBalance,
          kind: DetailValueKind.monoBold,
          emphasised: true,
        ),
      ],
    );
  }

  static Widget _failureCard(TransferFailedView result) {
    final statusCode = result.statusCode;
    final balance = result.balance;
    return DetailCard(
      header: Container(
        color: AppColors.brandTint,
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.reason,
              style: AppTextStyles.monoStatusLarge.copyWith(
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              result.explanation,
              style: AppTextStyles.bannerBody.copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
      rows: [
        DetailRow(
          label: 'BENEFICIARY',
          value: result.beneficiaryName,
          kind: DetailValueKind.name,
        ),
        if (statusCode != null) DetailRow(label: 'RESPONSE', value: statusCode),
        if (balance != null)
          DetailRow(
            label: 'BALANCE',
            value: balance,
            kind: DetailValueKind.monoBold,
            emphasised: true,
          ),
      ],
    );
  }
}

/// "₹1,500.00 sent to Rahul Sharma." with the amount in bold mono.
class _SuccessSummary extends StatelessWidget {
  const _SuccessSummary(this.result);

  final TransferSucceededView result;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.inkMuted),
        children: [
          TextSpan(
            text: result.amount,
            style: AppTextStyles.monoValueBold.copyWith(color: AppColors.ink),
          ),
          TextSpan(text: ' sent to ${result.beneficiaryName}.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
