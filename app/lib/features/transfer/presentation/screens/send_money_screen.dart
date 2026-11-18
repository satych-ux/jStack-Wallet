import 'package:flutter/material.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/jwallet_button.dart';
import '../../../../core/widgets/jwallet_text_field.dart';
import '../../domain/validators/transfer_validators.dart';
import '../models/transfer_draft.dart';
import '../widgets/balance_strip.dart';

/// Send money form (TRF-01, TRF-02).
///
/// Validates on "Review transfer" and hands a trimmed [TransferDraft] to
/// [onSubmit]. It never compares the amount with the balance: the balance
/// strip is for the user's information only; the backend decides (TRF-08).
class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({
    super.key,
    this.availableBalance = const SectionLoading(),
    this.initialDraft,
    required this.onSubmit,
    required this.onBack,
  });

  /// Pre-fills the form, e.g. when editing a transfer the backend refused.
  final TransferDraft? initialDraft;

  /// Formatted, e.g. `₹25,450.75`.
  final Section<String> availableBalance;
  final void Function(TransferDraft draft) onSubmit;
  final VoidCallback onBack;

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

enum _Field { amount, beneficiary, mobile, remarks }

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final Map<_Field, TextEditingController> _controllers = {
    for (final field in _Field.values) field: TextEditingController(),
  };

  /// Only fields that currently have an error are present.
  Map<_Field, String> _errors = {};

  static const double _fieldGap = 20;

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft case final draft?) {
      _controllers[_Field.amount]!.text = draft.amount;
      _controllers[_Field.beneficiary]!.text = draft.beneficiaryName;
      _controllers[_Field.mobile]!.text = draft.mobileNumber;
      _controllers[_Field.remarks]!.text = draft.remarks ?? '';
    }
    // An error goes away as soon as the user edits the field it is about.
    for (final field in _Field.values) {
      _controllers[field]!.addListener(() {
        if (_errors.containsKey(field)) {
          setState(() => _errors = Map.of(_errors)..remove(field));
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(_Field field) => _controllers[field]!.text.trim();

  void _submit() {
    final errors = <_Field, String?>{
      _Field.amount: validateAmount(_text(_Field.amount)),
      _Field.beneficiary: validateBeneficiaryName(_text(_Field.beneficiary)),
      _Field.mobile: validateMobile(_text(_Field.mobile)),
      _Field.remarks: validateRemarks(_text(_Field.remarks)),
    };
    setState(() {
      _errors = {
        for (final MapEntry(:key, :value) in errors.entries) key: ?value,
      };
    });
    if (_errors.isNotEmpty) return;

    final remarks = _text(_Field.remarks);
    widget.onSubmit(
      TransferDraft(
        amount: _text(_Field.amount),
        beneficiaryName: _text(_Field.beneficiary),
        mobileNumber: _text(_Field.mobile),
        remarks: remarks.isEmpty ? null : remarks,
      ),
    );
  }

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
          // Bar on top, form scrolls, note and button stay at the bottom
          // (above the keyboard when it is open).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopBar(title: 'Send money', onBack: widget.onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s14,
                    bottom: AppSpacing.s20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BalanceStrip(balance: widget.availableBalance),
                      const SizedBox(height: AppSpacing.s26),
                      AmountField(
                        controller: _controllers[_Field.amount],
                        hint: '0.00',
                        errorText: _errors[_Field.amount],
                      ),
                      const SizedBox(height: _fieldGap),
                      JWalletTextField(
                        label: 'BENEFICIARY NAME',
                        hint: 'Full name',
                        controller: _controllers[_Field.beneficiary],
                        errorText: _errors[_Field.beneficiary],
                      ),
                      const SizedBox(height: _fieldGap),
                      JWalletTextField(
                        label: 'MOBILE NUMBER',
                        hint: '10-digit number',
                        controller: _controllers[_Field.mobile],
                        errorText: _errors[_Field.mobile],
                        kind: JWalletFieldKind.phone,
                      ),
                      const SizedBox(height: _fieldGap),
                      JWalletTextField(
                        label: 'REMARKS',
                        hint: 'What is it for?',
                        controller: _controllers[_Field.remarks],
                        errorText: _errors[_Field.remarks],
                        isOptional: true,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'The backend checks your balance and completes the transfer. '
                'Nothing is deducted until it confirms.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.inkFaint,
                ),
              ),
              const SizedBox(height: AppSpacing.s14),
              JWalletButton(label: 'Review transfer', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
