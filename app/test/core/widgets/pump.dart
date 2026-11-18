import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/theme/app_theme.dart';

/// Pumps [child] inside the app theme at phone [width] (with the 20px
/// screen gutters), so widgets see the same
/// theme and constraints they get in a real screen.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  double width = 390,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The [BoxDecoration] of the first [DecoratedBox] under [of].
BoxDecoration firstDecoration(WidgetTester tester, Finder of) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

/// Finds a circle painted in [color].
Finder findDot(Color color) {
  return find.byWidgetPredicate((widget) {
    if (widget is! DecoratedBox) return false;
    final decoration = widget.decoration;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == color;
  });
}

/// The style of the [Text] showing exactly [text].
TextStyle styleOf(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style!;
}
