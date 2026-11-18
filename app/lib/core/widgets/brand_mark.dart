import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// The jWallet mark: a red card behind a black card, with a white dot.
/// Geometry is from DESIGN.md (`BrandMark`), drawn on a 40x40 grid.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'jWallet Lite',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: const _BrandMarkPainter(),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  /// The design grid the coordinates below are written against.
  static const double _grid = 40;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid, size.height / _grid);

    const radius = Radius.circular(5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(1, 8, 27, 19), radius),
      Paint()..color = AppColors.brand,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(11, 13, 27, 19), radius),
      Paint()..color = AppColors.ink,
    );
    canvas.drawCircle(
      const Offset(31, 22.5),
      2.6,
      Paint()..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) => false;
}
