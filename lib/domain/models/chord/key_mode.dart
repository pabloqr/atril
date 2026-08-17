enum KeyMode(final String symbol, final Set<String> aliases) {
  major('', {'', 'maj', '^'}),
  minor('m', {'m', 'mi', 'min', '-'});

  static final lookupByAlias = Map<String, KeyMode>.unmodifiable({
    for (final mode in values)
      for (final alias in mode.aliases) alias: mode,
  });
}
