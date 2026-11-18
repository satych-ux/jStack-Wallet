import 'package:flutter/painting.dart';

/// Every colour in the app. Values come from DESIGN.md section 1.
///
/// This file and `app_text_styles.dart` are the only files allowed to hold a
/// literal hex value.
abstract final class AppColors {
  // Text and surfaces
  static const Color ink = Color(0xFF0F0F0F);

  /// Dims the screen behind the debug panel: [ink] at 40%.
  static const Color scrim = Color(0x660F0F0F);
  static const Color inkMuted = Color(0xFF6A6A6A);
  static const Color inkFaint = Color(0xFF767676);
  static const Color line = Color(0xFFE3E3E3);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color white = Color(0xFFFFFFFF);

  // Brand and status
  static const Color brand = Color(0xFFB71A1A);
  static const Color brandPressed = Color(0xFF8E1414);
  static const Color brandTint = Color(0xFFF8EDED);
  static const Color success = Color(0xFF1A6B4A);
  static const Color successTint = Color(0xFFECF4F0);

  // On the dark balance panel
  static const Color onDarkMuted = Color(0xFF9E9E9E);
  static const Color onDarkValue = Color(0xFFE8E8E8);
  static const Color onDarkLabel = Color(
    0xFF8A8A8A,
  ); // WALLET ID / ACCOUNT labels
  static const Color darkDivider = Color(0xFF2B2B2B);

  // Loading placeholders
  static const Color skeleton = Color(0xFFEDEDED);
  static const Color skeletonFaint = Color(0xFFF2F2F2);
  static const Color shimmerBase = Color(0xFFEBEBEB);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseOnDark = Color(0xFF2B2B2B);
  static const Color shimmerHighlightOnDark = Color(0xFF3C3C3C);
}
