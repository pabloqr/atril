/// Shared regular expressions for Atril's supported ChordPro syntax.
///
/// These patterns recognize structure only. Semantic conversion and error
/// reporting remain the responsibility of the codecs and source editor.
abstract final class Patterns {
  const Patterns._();

  /// A complete directive with a non-empty value when a colon is present.
  ///
  /// Used by the parser, where incomplete editor input must be diagnosed.
  static final RegExp directiveStrict = RegExp(
    r'^[ \t]*\{[ \t]*(?<key>[a-z][a-z0-9_-]*)[ \t]*(?::[ \t]*(?<value>\S(?:[^{}\r\n]*\S)?)[ \t]*)?\}[ \t]*$',
  );

  /// A complete directive that permits an empty value after the colon.
  ///
  /// Used by source editing so templates such as `{title: }` remain selectable
  /// and can be completed in place.
  static final RegExp directivePermissive = RegExp(
    r'^[ \t]*\{[ \t]*(?<key>[a-z][a-z0-9_-]*)[ \t]*(?::[ \t]?(?<value>(?=[^{}\r\n])[ \t]*[^{}\r\n]+)?)?[ \t]*\}[ \t]*$',
  );

  /// A complete chord symbol split into root, extension, and optional bass.
  static final RegExp chord = RegExp(r'^(?<root>[A-G][#b]?)(?<extension>[^/]*)(?:/(?<bass>[A-G][#b]?))?$');

  /// An inline chord marker with its bracket-free content in `chord`.
  static final RegExp chordInline = RegExp(r'\[(?<chord>[^\[\]\r\n]*)\]');
}
