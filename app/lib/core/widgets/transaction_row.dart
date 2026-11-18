import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'status_label.dart';

enum TxnDirection { debit, credit }

/// Dashboard rows have 11px vertical padding; history rows have 10px.
enum RailDensity { dashboard, history }

/// Display-ready values for one row. Formatting happens before this is built.
class TransactionRowData {
  const TransactionRowData({
    required this.name,
    required this.reference,
    required this.metaLabel,
    required this.amount,
    required this.direction,
    required this.status,
  });

  final String name;
  final String reference;

  /// Second meta span after the reference: the date on the dashboard
  /// (`20 Oct`), the type on history (`DEBIT`).
  final String metaLabel;

  /// Unsigned, e.g. `1,500.00`. The row adds `−` or `+`.
  final String amount;
  final TxnDirection direction;
  final StatusKind status;
}

/// One transaction on the rail: a coloured dot over the rail line, name and
/// meta on the left, signed amount and status on the right.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.data,
    this.onTap,
    this.density = RailDensity.dashboard,
  });

  final TransactionRowData data;
  final VoidCallback? onTap;
  final RailDensity density;

  /// Left padding clears the rail; shared with TransactionRowShimmer.
  static EdgeInsets paddingFor(RailDensity density) => switch (density) {
    RailDensity.dashboard => const EdgeInsets.fromLTRB(36, 11, 0, 11),
    RailDensity.history => const EdgeInsets.fromLTRB(36, 10, 0, 10),
  };

  /// Gap between the two lines of each column.
  static const double lineGap = 3;

  @override
  Widget build(BuildContext context) {
    final isDebit = data.direction == TxnDirection.debit;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Padding(
              padding: paddingFor(density),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.rowTitle.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: lineGap),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                data.reference,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _meta,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s10),
                            Text(data.metaLabel, style: _meta),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isDebit ? '−' : '+'}${data.amount}',
                        style: AppTextStyles.monoValueBold.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: lineGap),
                      StatusLabel(status: data.status),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: RailDot.left,
              top: 0,
              bottom: 0,
              child: Center(
                child: RailDot(
                  color: isDebit ? AppColors.brand : AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final TextStyle _meta = AppTextStyles.monoMeta.copyWith(
    color: AppColors.inkFaint,
  );
}

/// A 9px dot inside a 13px white ring. The ring hides the rail line behind
/// the dot.
class RailDot extends StatelessWidget {
  const RailDot({super.key, required this.color});

  final Color color;

  /// The ring's left edge, so the 9px dot sits at left 9 and centres on the
  /// rail line at left 13.
  static const double left = 7;
  static const double _ring = 13;
  static const double _dot = 9;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ring,
      height: _ring,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
