import 'package:atril/features/core/utils/widget_side.dart';
import 'package:atril/features/core/utils/widget_utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetUtilities.calculateListWidgetSide', () {
    test('classifies first, middle, last, and single item positions', () {
      expect(WidgetUtilities.calculateListWidgetSide(0, 1), WidgetSide.all);
      expect(WidgetUtilities.calculateListWidgetSide(0, 3), WidgetSide.top);
      expect(WidgetUtilities.calculateListWidgetSide(1, 3), WidgetSide.none);
      expect(WidgetUtilities.calculateListWidgetSide(2, 3), WidgetSide.bottom);
    });
  });

  group('WidgetUtilities.calculateBorderRadius', () {
    test('builds the expected radius for top and none sides', () {
      expect(
        WidgetUtilities.calculateBorderRadius(WidgetSide.top, 12),
        const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(4)),
      );
      expect(WidgetUtilities.calculateBorderRadius(WidgetSide.none, 12), BorderRadius.circular(4));
    });
  });
}
