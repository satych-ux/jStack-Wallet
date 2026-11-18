import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_colors.dart';
import 'package:j_stack_flutter_app/core/theme/app_text_styles.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('brand, ink and success match DESIGN.md', () {
      expect(AppColors.brand, const Color(0xFFB71A1A));
      expect(AppColors.ink, const Color(0xFF0F0F0F));
      expect(AppColors.success, const Color(0xFF1A6B4A));
    });
  });

  group('AppTextStyles', () {
    test('balance is Space Mono 700 at 34', () {
      expect(AppTextStyles.balance.fontFamily, 'Space Mono');
      expect(AppTextStyles.balance.fontWeight, FontWeight.w700);
      expect(AppTextStyles.balance.fontSize, 34);
    });

    test('display is Sora 600', () {
      expect(AppTextStyles.display.fontFamily, 'Sora');
      expect(AppTextStyles.display.fontWeight, FontWeight.w600);
    });

    test('body is Manrope 500', () {
      expect(AppTextStyles.body.fontFamily, 'Manrope');
      expect(AppTextStyles.body.fontWeight, FontWeight.w500);
    });
  });

  group('appTheme', () {
    test('cards and app bars have no elevation', () {
      expect(appTheme.cardTheme.elevation, 0);
      expect(appTheme.appBarTheme.elevation, 0);
    });
  });
}
