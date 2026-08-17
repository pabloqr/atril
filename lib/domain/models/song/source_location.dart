/// A source span associated with a parser diagnostic.
///
/// [sourceOffset] is zero-based for direct string operations. [lineIndex] and
/// [position] are one-based for display in editors and validation messages.
final class SourceLocation({
  /// The zero-based character offset from the start of the source document.
  required final int sourceOffset,

  /// The one-based source line number.
  required final int lineIndex,

  /// The one-based character position within [lineIndex].
  required final int position,

  /// The number of source characters covered by the diagnostic.
  required final int length,
});
