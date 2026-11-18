import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/detail_card.dart';
import '../../../../core/widgets/jwallet_button.dart';
import '../models/confirmation_view.dart';

/// Review before sending (TRF-03..05).
///
/// Shows what will be sent and the [requestKey] (the Idempotency-Key, made
/// when this screen opens and reused on every retry of this attempt).
/// While [isSubmitting], Confirm shows a spinner and ignores taps, and
/// Edit / back are inert, so one attempt sends one request. Taps landing in
/// the same frame are dropped by the bloc's `droppable()` transformer.
class ConfirmTransferScreen extends StatelessWidget {
  const ConfirmTransferScreen({
    super.key,
    required this.details,
    required this.requestKey,
    this.isSubmitting = false,
    required this.onConfirm,
    required this.onBack,
  });

  final ConfirmationView details;
  final String requestKey;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  /// Back arrow and "Edit details": return to the form.
  final VoidCallback onBack;

  static const double _blockGap = 30;
  static const double _keyGap = 16;

  void _back() {
    if (!isSubmitting) onBack();
  }

  @override
  Widget build(BuildContext context) {
    final remarks = details.remarks;
    final balanceAfter = details.balanceAfter;
    return PopScope(
      // No system back while the request is in flight.
      canPop: !isSubmitting,
      child: Scaffold(
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
                AppTopBar(title: 'Review transfer', onBack: _back),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: _blockGap,
                      bottom: AppSpacing.s20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AmountBlock(
                          amount: details.amount,
                          name: details.beneficiaryName,
                        ),
                        const SizedBox(height: _blockGap),
                        DetailCard(
                          rows: [
                            DetailRow(
                              label: 'BENEFICIARY',
                              value: details.beneficiaryName,
                              kind: DetailValueKind.name,
                            ),
                            DetailRow(
                              label: 'MOBILE',
                              value: details.mobileNumber,
                            ),
                            if (remarks != null)
                              DetailRow(
                                label: 'REMARKS',
                                value: remarks,
                                kind: DetailValueKind.text,
                              ),
                            DetailRow(
                              label: 'TRANSFER FEE',
                              value: details.fee,
                            ),
                            if (balanceAfter != null)
                              DetailRow(
                                label: 'BALANCE AFTER',
                                value: balanceAfter,
                                kind: DetailValueKind.monoBold,
                                emphasised: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s18),
                        Text(
                          'Confirming sends the transfer once. If the network '
                          'drops, retrying reuses the same request key, so you '
                          'cannot be debited twice.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _RequestKeyLine(requestKey: requestKey),
                const SizedBox(height: _keyGap),
                JWalletButton(
                  label: isSubmitting ? 'Sending' : 'Confirm transfer',
                  onPressed: onConfirm,
                  variant: isSubmitting
                      ? JWalletButtonVariant.loading
                      : JWalletButtonVariant.primary,
                ),
                const SizedBox(height: AppSpacing.s10),
                JWalletButton(
                  label: 'Edit details',
                  onPressed: _back,
                  variant: isSubmitting
                      ? JWalletButtonVariant.disabled
                      : JWalletButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.amount, required this.name});

  final String amount;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'YOU ARE SENDING',
          style: AppTextStyles.monoLabel.copyWith(color: AppColors.inkFaint),
        ),
        const SizedBox(height: AppSpacing.s12),
        // Very large amounts shrink rather than overflow.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: AppTextStyles.amountHero.copyWith(color: AppColors.ink),
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Text(
          'to $name',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _RequestKeyLine extends StatelessWidget {
  const _RequestKeyLine({required this.requestKey});

  final String requestKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'REQUEST KEY',
          style: AppTextStyles.panelLabel.copyWith(color: AppColors.inkFaint),
        ),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          child: Text(
            requestKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.monoTiny.copyWith(color: AppColors.inkFaint),
          ),
        ),
      ],
    );
  }
}
