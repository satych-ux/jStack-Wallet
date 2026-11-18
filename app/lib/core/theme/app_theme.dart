import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// The app's single [ThemeData]. Flat: no elevation, no shadows, no tint.
/// Separation comes from hairlines (`line`) and `surface`.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: AppTextStyles.manrope,
  scaffoldBackgroundColor: AppColors.white,
  colorScheme: const ColorScheme.light(
    primary: AppColors.brand,
    onPrimary: AppColors.white,
    secondary: AppColors.ink,
    onSecondary: AppColors.white,
    error: AppColors.brand,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.ink,
    outline: AppColors.line,
    surfaceTint: Colors.transparent,
  ),
  textTheme: const TextTheme(
    displaySmall: AppTextStyles.display,
    headlineSmall: AppTextStyles.headline,
    titleLarge: AppTextStyles.titleName,
    titleMedium: AppTextStyles.titleAppBar,
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.bodySmall,
    bodySmall: AppTextStyles.caption,
    labelLarge: AppTextStyles.buttonLabel,
  ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
  appBarTheme: AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.ink,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: AppTextStyles.titleAppBar.copyWith(color: AppColors.ink),
  ),
  cardTheme: const CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: AppColors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusCard)),
      side: BorderSide(color: AppColors.line, width: AppSpacing.borderWidth),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.line,
    thickness: AppSpacing.borderWidth,
    space: AppSpacing.borderWidth,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.brand,
  ),
);
