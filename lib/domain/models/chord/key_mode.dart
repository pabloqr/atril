enum KeyMode {
  major('', {'', 'maj', '^'}),
  minor('m', {'m', 'mi', 'min', '-'});

  const KeyMode(this.symbol, this.aliases);

  final String symbol;
  final Set<String> aliases;

  static final lookupByAlias = Map<String, KeyMode>.unmodifiable({
    for (final mode in values)
      for (final alias in mode.aliases) alias: mode,
  });
}
