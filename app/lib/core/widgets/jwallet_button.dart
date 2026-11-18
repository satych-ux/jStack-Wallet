import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum JWalletButtonVariant { primary, secondary, disabled, loading }

/// Full-width 52px button. Only [JWalletButtonVariant.primary] and
/// [JWalletButtonVariant.secondary] respond to taps; disabled and loading
/// ignore them, so a double tap during a request cannot fire twice.
class JWalletButton extends StatelessWidget {
  const JWalletButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = JWalletButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final JWalletButtonVariant variant;

  static const double _spinnerSize = 18;
  static const double _spinnerGap = 10;

  bool get _tappable =>
      variant == JWalletButtonVariant.primary ||
      variant == JWalletButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      width: double.infinity,
      child: TextButton(
        onPressed: _tappable ? onPressed : null,
        style: _style(variant),
        child: variant == JWalletButtonVariant.loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: _spinnerSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: _spinnerGap),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }

  static ButtonStyle _style(JWalletButtonVariant variant) {
    final (
      Color background,
      Color foreground,
      BorderSide side,
    ) = switch (variant) {
      JWalletButtonVariant.primary => (
        AppColors.brand,
        AppColors.white,
        BorderSide.none,
      ),
      JWalletButtonVariant.secondary => (
        AppColors.white,
        AppColors.ink,
        const BorderSide(color: AppColors.line, width: AppSpacing.borderWidth),
      ),
      JWalletButtonVariant.disabled => (
        AppColors.line,
        AppColors.inkFaint,
        BorderSide.none,
      ),
      JWalletButtonVariant.loading => (
        AppColors.brand,
        AppColors.white,
        BorderSide.none,
      ),
    };

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            variant == JWalletButtonVariant.primary &&
                states.contains(WidgetState.pressed)
            ? AppColors.brandPressed
            : background,
      ),
      foregroundColor: WidgetStatePropertyAll(foreground),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStatePropertyAll(side),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: const WidgetStatePropertyAll(AppTextStyles.buttonLabel),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusButton),
          ),
        ),
      ),
    );
  }
}
