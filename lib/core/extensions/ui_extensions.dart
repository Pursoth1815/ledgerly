import 'package:flutter/widgets.dart';

extension WidgetSpacingExtensions on Widget {
  Widget p(double value) => Padding(padding: EdgeInsets.all(value), child: this);

  Widget p16() => p(16);
  Widget p12() => p(12);
  Widget p8() => p(8);

  Widget ps({double paddingVertical = 0.0, double paddingHorizontal = 0.0}) => Padding(
    padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
    child: this,
  );
}

extension WidgetLayoutExtensions on Widget {
  Widget get center => Center(child: this);

  Widget get expanded => Expanded(child: this);

  Widget align(Alignment alignment) => Align(alignment: alignment, child: this);
}

extension WidgetVisibilityExtensions on Widget {
  Widget showIf(bool condition) => condition ? this : const SizedBox.shrink();

  Widget opacity(double value) => Opacity(opacity: value, child: this);

  Widget ignore({bool ignoring = true}) => IgnorePointer(ignoring: ignoring, child: this);
}

extension WidgetSizeExtensions on Widget {
  Widget sized({double? width, double? height}) => SizedBox(width: width, height: height, child: this);
}

extension DurationX on int {
  Duration get ms => Duration(milliseconds: this);
}
