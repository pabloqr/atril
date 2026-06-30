enum AppColorPalette {
  amber(0xFFB86B00),
  blue(0xFF315A7D),
  olive(0xFF6F7D3C);

  const AppColorPalette(this.seedValue);

  final int seedValue;
}

enum AppContrastLevel {
  normal(0),
  medium(0.5),
  high(1);

  const AppContrastLevel(this.materialValue);

  final double materialValue;
}

enum LibrarySortOrder { title, artist }
