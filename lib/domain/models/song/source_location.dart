/// A source span associated with a parser diagnostic.
///
/// [sourceOffset] is zero-based for direct string operations. [lineIndex] and
/// [position] are one-based for display in editors and validation messages.
final class SourceLocation {
  /// Creates a source span of [length] characters.
  SourceLocation({required this.sourceOffset, required this.lineIndex, required this.position, required this.length});

  /// The zero-based character offset from the start of the source document.
  final int sourceOffset;

  /// The one-based source line number.
  final int lineIndex;

  /// The one-based character position within [lineIndex].
  final int position;

  /// The number of source characters covered by the diagnostic.
  final int length;
}
