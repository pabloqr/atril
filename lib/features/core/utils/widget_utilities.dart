import 'package:atril/features/core/utils/widget_side.dart';
import 'package:flutter/material.dart';

enum ButtonWidth { regular, narrow, wide }

abstract final class WidgetStyleUtilities {
  static ButtonStyle? iconButtonStyle(ButtonWidth width) {
    return switch (width) {
      ButtonWidth.regular => null,
      ButtonWidth.narrow => IconButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        minimumSize: const Size(32.0, 40.0),
      ),
      ButtonWidth.wide => IconButton.styleFrom(minimumSize: const Size(52.0, 40.0)),
    };
  }
}

abstract final class WidgetUtilities {
  static WidgetSide calculateListWidgetSide(int index, int lenght) {
    if (lenght <= 1) return WidgetSide.all;
    if (index == 0) return WidgetSide.top;
    if (index == lenght - 1) return WidgetSide.bottom;
    return WidgetSide.none;
  }

  static BorderRadius calculateBorderRadius(WidgetSide side, [double radius = 28.0]) {
    return switch (side) {
      WidgetSide.all => BorderRadius.circular(radius),
      WidgetSide.left => BorderRadius.horizontal(left: Radius.circular(radius), right: const Radius.circular(4.0)),
      WidgetSide.top => BorderRadius.vertical(top: Radius.circular(radius), bottom: const Radius.circular(4.0)),
      WidgetSide.right => BorderRadius.horizontal(left: const Radius.circular(4.0), right: Radius.circular(radius)),
      WidgetSide.bottom => BorderRadius.vertical(top: const Radius.circular(4.0), bottom: Radius.circular(radius)),
      WidgetSide.topLeft => BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: const Radius.circular(4.0),
        bottomLeft: const Radius.circular(4.0),
        bottomRight: const Radius.circular(4.0),
      ),
      WidgetSide.topRight => BorderRadius.only(
        topLeft: const Radius.circular(4.0),
        topRight: Radius.circular(radius),
        bottomLeft: const Radius.circular(4.0),
        bottomRight: const Radius.circular(4.0),
      ),
      WidgetSide.bottomLeft => BorderRadius.only(
        topLeft: const Radius.circular(4.0),
        topRight: const Radius.circular(4.0),
        bottomLeft: Radius.circular(radius),
        bottomRight: const Radius.circular(4.0),
      ),
      WidgetSide.bottomRight => BorderRadius.only(
        topLeft: const Radius.circular(4.0),
        topRight: const Radius.circular(4.0),
        bottomLeft: const Radius.circular(4.0),
        bottomRight: Radius.circular(radius),
      ),
      WidgetSide.none => BorderRadius.circular(4.0),
    };
  }
}
