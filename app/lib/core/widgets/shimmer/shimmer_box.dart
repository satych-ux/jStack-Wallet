import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Owns the one [AnimationController] for a shimmering section and hands it
/// to every [ShimmerBox] below, so twenty boxes do not run twenty
/// controllers. Wraps the section in a [RepaintBoundary] so the sweep only
/// repaints this section, not the whole screen.
class ShimmerGroup extends StatefulWidget {
  const ShimmerGroup({super.key, required this.child});

  final Widget child;

  static const Duration period = Duration(milliseconds: 1400);

  /// The shared animation, or null when there is no ShimmerGroup above
  /// (the box then paints its flat base colour).
  static Animation<double>? animationOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  State<ShimmerGroup> createState() => _ShimmerGroupState();
}

class _ShimmerGroupState extends State<ShimmerGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ShimmerGroup.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _ShimmerScope(animation: _controller, child: widget.child),
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      animation != oldWidget.animation;
}

/// A rounded placeholder block. Leave [width] null to fill the parent.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 4,
    this.onDark = false,
  });

  final double? width;
  final double height;
  final double radius;

  /// Use the darker pair on the ink balance panel.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final base = onDark ? AppColors.shimmerBaseOnDark : AppColors.shimmerBase;
    final highlight = onDark
        ? AppColors.shimmerHighlightOnDark
        : AppColors.shimmerHighlight;
    final borderRadius = BorderRadius.circular(radius);
    final animation = ShimmerGroup.animationOf(context);

    if (animation == null) {
      return _box(BoxDecoration(color: base, borderRadius: borderRadius));
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // The gradient is two box-widths wide and slides from fully left of
        // the box (t = 0) to fully right of it (t = 1).
        final t = animation.value;
        return _box(
          BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-3 + 4 * t, 0),
              end: Alignment(-1 + 4 * t, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }

  Widget _box(BoxDecoration decoration) => SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(decoration: decoration),
  );
}

/// Reserves one line of [style]'s height and places [box] in it, so a
/// placeholder takes exactly the space of the text it stands in for and
/// nothing jumps when the real content arrives.
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({
    super.key,
    required this.style,
    required this.box,
    this.alignment = Alignment.centerLeft,
  });

  final TextStyle style;
  final Widget box;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTextStyles.lineHeightOf(context, style),
      child: Align(alignment: alignment, child: box),
    );
  }
}
