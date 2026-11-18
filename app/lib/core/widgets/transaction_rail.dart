import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A vertical hairline with rows built over it. Rows are usually
/// TransactionRow or TransactionRowShimmer.
///
/// The list is shrink-wrapped and does not scroll itself: it sits inside the
/// screen's own scroll view (one rail per day group on History).
class TransactionRail extends StatelessWidget {
  const TransactionRail({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  static const double _lineLeft = 13;
  static const double _lineInset = 14;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: _lineLeft,
          top: _lineInset,
          bottom: _lineInset,
          width: AppSpacing.borderWidth,
          child: ColoredBox(color: AppColors.line),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ],
    );
  }
}
