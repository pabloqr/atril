/// Search helpers used while constructing source-edit selections.
extension StringExtension on String {
  /// Returns the index of the first occurrence of any string in [chars].
  ///
  /// Returns `-1` when none occur. Each entry is escaped before the temporary
  /// character class is built, so punctuation is matched literally.
  int indexOfAny(List<String> chars) {
    final match = RegExp('[${chars.map(RegExp.escape).join()}]').firstMatch(this);
    return match?.start ?? -1;
  }
}
