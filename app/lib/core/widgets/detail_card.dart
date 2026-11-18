import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// How a [DetailRow] value is set. Ids, amounts, dates and phone numbers are
/// mono; human names and free text are Manrope; a status is mono caps.
enum DetailValueKind { mono, monoBold, name, text, status }

/// Bordered card of label/value rows with a hairline between rows.
/// An optional [header] (e.g. the failure banner) sits above the rows,
/// inside the same border.
class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.rows, this.header});

  final List<DetailRow> rows;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Container(
      // The border is painted in front of the rows: painted behind, a
      // filled row would cover its curve at the rounded corners.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.line,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          if (header != null && rows.isNotEmpty) const Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) => rows[index],
          ),
        ],
      ),
    );
  }
}

/// One line of a [DetailCard]: mono label on the left, value on the right.
/// Pass [label] in uppercase.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.kind = DetailValueKind.mono,
    this.valueColor = AppColors.ink,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final DetailValueKind kind;
  final Color valueColor;

  /// The last, important row (e.g. balance after) sits on `surface`.
  final bool emphasised;

  static const EdgeInsets padding = EdgeInsets.symmetric(
    vertical: 15,
    horizontal: AppSpacing.s16,
  );

  TextStyle get _valueStyle => switch (kind) {
    DetailValueKind.mono => AppTextStyles.monoValue,
    DetailValueKind.monoBold => AppTextStyles.monoValueBold,
    DetailValueKind.name => AppTextStyles.detailName,
    DetailValueKind.text => AppTextStyles.detailText,
    DetailValueKind.status => AppTextStyles.monoStatusLarge,
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: emphasised ? AppColors.surface : AppColors.white,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Text(
              label,
              style: AppTextStyles.monoLabelTight.copyWith(
                color: AppColors.inkFaint,
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: _valueStyle.copyWith(color: valueColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
