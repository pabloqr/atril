/// A named instruction embedded in a song document.
///
/// Directives represent structured information that is not lyric text. Common
/// examples in chord-sheet formats are metadata entries such as a title,
/// section markers such as a chorus, or rendering hints.
///
/// The directive [name] is normalized to lowercase when the directive is
/// created. The model does not trim, validate, interpret aliases, or preserve
/// the original spelling of the name; parsers that need that source detail
/// should keep it separately.
///
/// The optional [value] is generic because different directives can carry
/// different payload shapes. For example, a metadata directive may use a
/// [String] value, while a richer parser could attach a typed object.
final class Directive<T> {
  /// Creates a directive with a required [name] and an optional typed [value].
  ///
  /// [name] is converted to lowercase immediately so later comparisons can use
  /// the stored value consistently.
  Directive({required String name, this.value}) : name = name.toLowerCase();

  /// The normalized identifier for this directive.
  ///
  /// It may be a canonical name, an alias, or a custom directive name depending
  /// on the parser or source format that produced it. Only lowercase
  /// normalization is guaranteed.
  final String name;

  /// The optional payload associated with [name].
  ///
  /// A `null` value represents a valueless directive, not the absence of the
  /// directive itself.
  final T? value;
}
