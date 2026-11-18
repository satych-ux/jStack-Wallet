import 'package:flutter/widgets.dart';

/// Every text style in the app. Values come from DESIGN.md section 1.
///
/// Rule: money, references, ids, dates and status labels are Space Mono;
/// prose is Manrope; headings are Sora.
///
/// Letter spacing in DESIGN.md is in `em`; Flutter wants logical pixels, so
/// each value is written as `em * fontSize`.
///
/// Styles marked "uppercase" expect the caller to pass uppercase text;
/// TextStyle cannot transform case.
abstract final class AppTextStyles {
  static const String spaceMono = 'Space Mono';
  static const String sora = 'Sora';
  static const String manrope = 'Manrope';

  // Space Mono: money
  static const TextStyle balance = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 34,
    height: 1.0,
    letterSpacing: -0.01 * 34,
  );
  static const TextStyle amountHero = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 1.0,
    letterSpacing: -0.02 * 40,
  );
  static const TextStyle amountDetail = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 38,
    height: 1.0,
    letterSpacing: -0.02 * 38,
  );

  // Sora: headings
  static const TextStyle display = TextStyle(
    fontFamily: sora,
    fontWeight: FontWeight.w600,
    fontSize: 27,
    height: 1.18,
    letterSpacing: -0.02 * 27,
  );
  static const TextStyle headline = TextStyle(
    fontFamily: sora,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.2,
    letterSpacing: -0.015 * 24,
  );
  static const TextStyle titleAppBar = TextStyle(
    fontFamily: sora,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.2,
    letterSpacing: -0.01 * 18,
  );
  static const TextStyle titleName = TextStyle(
    fontFamily: sora,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    letterSpacing: -0.01 * 20,
  );
  static const TextStyle wordmark = TextStyle(
    fontFamily: sora,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.2,
    letterSpacing: -0.01 * 20,
  );

  // Manrope: prose and controls
  static const TextStyle body = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.5,
  );
  static const TextStyle rowTitle = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.0,
  );
  static const TextStyle pillLabel = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.0,
  );

  // Space Mono: labels, ids, statuses
  /// Uppercase.
  static const TextStyle monoLabel = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 0.14 * 11,
  );

  /// Uppercase.
  static const TextStyle monoLabelTight = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 0.12 * 11,
  );
  static const TextStyle monoMeta = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 1.2,
  );
  static const TextStyle monoValue = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle monoValueBold = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.2,
  );

  /// Uppercase.
  static const TextStyle monoStatus = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 10,
    height: 1.2,
    letterSpacing: 0.1 * 10,
  );

  /// Uppercase.
  static const TextStyle monoStatusLarge = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    height: 1.2,
    letterSpacing: 0.1 * 12,
  );

  // Component styles: one-off sizes DESIGN.md section 2 gives inline.

  /// AmountField prefix and input.
  static const TextStyle amountInput = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.2,
  );

  /// WALLET ID / ACCOUNT labels on the balance panel. Uppercase.
  static const TextStyle panelLabel = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 10,
    height: 1.2,
    letterSpacing: 0.12 * 10,
  );

  /// Wallet id and account values on the balance panel.
  static const TextStyle panelValue = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.2,
  );

  /// The SOON pill on a disabled quick action. Uppercase.
  static const TextStyle soonPill = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 9,
    height: 1.2,
    letterSpacing: 0.1 * 9,
  );

  static const TextStyle quickActionLabel = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.2,
  );

  /// "Optional" hint beside a field label.
  static const TextStyle fieldHint = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1.2,
  );

  static const TextStyle emptyTitle = TextStyle(
    fontFamily: sora,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.2,
  );

  static const TextStyle errorTitle = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.2,
  );

  /// Human names in a detail row.
  static const TextStyle detailName = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.2,
  );

  /// Free text (remarks) in a detail row.
  static const TextStyle detailText = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.2,
  );

  /// Inline text links such as "See all".
  static const TextStyle link = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.2,
  );

  /// Typed digits in a phone field: numbers are mono, at body size.
  static const TextStyle monoInput = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.2,
  );

  /// The amount in the Send money balance strip.
  static const TextStyle stripAmount = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 1.2,
  );

  /// The request key under the confirmation card.
  static const TextStyle monoTiny = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 10,
    height: 1.2,
  );

  /// Explanation text in the transfer-failure banner.
  static const TextStyle bannerBody = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.5,
  );

  /// Typed text and placeholder in the history search field.
  static const TextStyle searchInput = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.2,
  );

  /// Labels in the login demo-credentials card.
  static const TextStyle demoLabel = TextStyle(
    fontFamily: manrope,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.5,
  );

  /// Values in the login demo-credentials card.
  static const TextStyle demoValue = TextStyle(
    fontFamily: spaceMono,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.2,
  );

  /// Height of one rendered line of [style] at the current text scale.
  /// Measured rather than computed, because the engine rounds line heights.
  /// Shimmer placeholders and fixed-height text slots use this so nothing
  /// jumps when real content arrives.
  static double lineHeightOf(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}
