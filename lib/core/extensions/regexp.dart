/// Range helpers for named regular-expression groups.
extension RegExpMatchExtension on RegExpMatch {
  /// Returns the absolute half-open range of named capture [name].
  ///
  /// Returns `null` when the group did not participate in the match. The range
  /// is expressed against the original [RegExpMatch.input], not the matched
  /// substring.
  (int, int)? namedGroupRange(String name) {
    final value = namedGroup(name);
    if (value == null) return null;

    final matchedText = input.substring(start, end);
    final offset = matchedText.indexOf(value);
    if (offset == -1) return null;

    return (start + offset, start + offset + value.length);
  }
}
