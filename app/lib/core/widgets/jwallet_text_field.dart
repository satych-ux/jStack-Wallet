import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// What the field holds. Decides the keyboard and the extras:
/// [password] gets an eye toggle, [phone] gets a `+91` prefix.
enum JWalletFieldKind { text, email, password, phone }

/// Labelled 52px text field. Pass [label] in uppercase.
class JWalletTextField extends StatefulWidget {
  const JWalletTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.kind = JWalletFieldKind.text,
    this.isOptional = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final JWalletFieldKind kind;

  /// Shows an "Optional" hint at the right of the label.
  final bool isOptional;

  @override
  State<JWalletTextField> createState() => _JWalletTextFieldState();
}

class _JWalletTextFieldState extends State<JWalletTextField> {
  bool _obscured = true;

  static const double _prefixPadding = 14;

  bool get _isPassword => widget.kind == JWalletFieldKind.password;

  TextInputType get _keyboard => switch (widget.kind) {
    JWalletFieldKind.text => TextInputType.text,
    JWalletFieldKind.email => TextInputType.emailAddress,
    JWalletFieldKind.password => TextInputType.visiblePassword,
    JWalletFieldKind.phone => TextInputType.phone,
  };

  /// Phone numbers are digits, and digits are mono (DESIGN.md type rule).
  TextStyle get _inputStyle => widget.kind == JWalletFieldKind.phone
      ? AppTextStyles.monoInput
      : AppTextStyles.body;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      label: widget.label,
      isOptional: widget.isOptional,
      errorText: widget.errorText,
      height: AppSpacing.fieldHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.kind == JWalletFieldKind.phone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: _prefixPadding),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(
                    color: AppColors.line,
                    width: AppSpacing.borderWidth,
                  ),
                ),
              ),
              child: Text(
                '+91',
                style: AppTextStyles.monoValue.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Center(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _isPassword && _obscured,
                  keyboardType: _keyboard,
                  style: _inputStyle.copyWith(color: AppColors.ink),
                  cursorColor: AppColors.ink,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.inkFaint,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isPassword)
            IconButton(
              tooltip: _obscured ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscured = !_obscured),
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
              ),
              padding: EdgeInsets.zero,
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppSpacing.s20,
                color: AppColors.inkFaint,
              ),
            ),
        ],
      ),
    );
  }
}

/// 62px amount input with a `₹` prefix, both in Space Mono 700.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    this.controller,
    this.label = 'AMOUNT',
    this.hint,
    this.errorText,
  });

  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      label: label,
      errorText: errorText,
      height: AppSpacing.amountFieldHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Row(
          children: [
            Text(
              '₹',
              style: AppTextStyles.amountInput.copyWith(
                color: AppColors.inkFaint,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTextStyles.amountInput.copyWith(color: AppColors.ink),
                cursorColor: AppColors.ink,
                decoration: InputDecoration.collapsed(
                  hintText: hint,
                  hintStyle: AppTextStyles.amountInput.copyWith(
                    color: AppColors.line,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The parts every field shares: label above, bordered box, error below.
/// The border is `line`, `ink` while focused, `brand` on error.
class _FieldFrame extends StatefulWidget {
  const _FieldFrame({
    required this.label,
    required this.errorText,
    required this.height,
    required this.child,
    this.isOptional = false,
  });

  final String label;
  final String? errorText;
  final double height;
  final Widget child;
  final bool isOptional;

  @override
  State<_FieldFrame> createState() => _FieldFrameState();
}

class _FieldFrameState extends State<_FieldFrame> {
  bool _focused = false;

  static const double _errorGap = 7;
  static const double _errorDot = 5;

  Color get _borderColor {
    if (widget.errorText != null) return AppColors.brand;
    return _focused ? AppColors.ink : AppColors.line;
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppTextStyles.monoLabel.copyWith(
                color: AppColors.inkFaint,
              ),
            ),
            if (widget.isOptional) ...[
              const Spacer(),
              Text(
                'Optional',
                style: AppTextStyles.fieldHint.copyWith(
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: Container(
            height: widget.height,
            // Border in front of the content, so the +91 prefix's fill
            // cannot cover the border's rounded corners.
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
              border: Border.all(
                color: _borderColor,
                width: AppSpacing.borderWidth,
              ),
            ),
            child: widget.child,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: _errorGap),
          Row(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: _errorDot),
              ),
              const SizedBox(width: _errorGap),
              Expanded(
                child: Text(
                  error,
                  style: AppTextStyles.caption.copyWith(color: AppColors.brand),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
