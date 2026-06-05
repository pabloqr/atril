/// A named instruction embedded in a song document.
///
/// Directives represent structured information that is not lyric text. Common
/// examples in chord-sheet formats are metadata entries such as a title,
/// section markers such as a chorus, or rendering hints.
///
/// The directive [name] is intentionally kept as plain text so the domain model
/// can preserve names produced by different parsers or source formats. This
/// class does not normalize, validate, or interpret that name; consumers that
/// need case-insensitive comparisons should normalize it at the boundary where
/// the comparison is performed.
///
/// The optional [value] is generic because different directives can carry
/// different payload shapes. For example, a metadata directive may use a
/// [String] value, while a richer parser could attach a typed object.
final class Directive<T> {
  /// Creates a directive with a required [name] and an optional typed [value].
  Directive({required this.name, this.value});

  /// The source-level identifier for this directive.
  ///
  /// The model stores this value exactly as provided. It may be a canonical
  /// name, an alias, or a custom directive name depending on the parser or
  /// source format that produced it.
  final String name;

  /// The optional payload associated with [name].
  ///
  /// A `null` value represents a valueless directive, not the absence of the
  /// directive itself.
  final T? value;
}
