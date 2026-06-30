import 'package:atril/domain/models/settings/app_settings.dart';
import 'package:atril/features/core/theme/text_theme.dart';
import 'package:flutter/material.dart';

abstract final class AtrilTheme {
  /// Light appearance for the application shell.
  static ThemeData light({
    AppColorPalette colorPalette = AppColorPalette.blue,
    AppContrastLevel contrastLevel = AppContrastLevel.normal,
  }) => _build(Brightness.light, colorPalette, contrastLevel);

  /// Dark appearance for the application shell.
  static ThemeData dark({
    AppColorPalette colorPalette = AppColorPalette.blue,
    AppContrastLevel contrastLevel = AppContrastLevel.normal,
  }) => _build(Brightness.dark, colorPalette, contrastLevel);

  static ThemeData _build(Brightness brightness, AppColorPalette colorPalette, AppContrastLevel contrastLevel) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Color(colorPalette.seedValue),
      brightness: brightness,
      contrastLevel: contrastLevel.materialValue,
    );
    final base = ThemeData(colorScheme: colorScheme, brightness: brightness, useMaterial3: true);
    final textTheme = textThemeDefinition;

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        backgroundColor: colorScheme.tertiaryContainer,
        labelStyle: base.chipTheme.labelStyle?.copyWith(color: colorScheme.onTertiaryContainer),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))),
          padding: WidgetStatePropertyAll(const EdgeInsets.all(4.0)),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
        ),
      ),
    );
  }
}
