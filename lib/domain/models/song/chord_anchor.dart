import 'package:atril/domain/models/chord/chord.dart';

/// A chord positioned relative to lyric text.
///
/// A [ChordAnchor] connects a parsed [chord] to an [offset] inside the lyric
/// line that owns it. The anchor does not contain the lyric text itself; it is
/// meant to be stored alongside the text in a `LyricLine`.
///
/// The [offset] is a domain-level character position. This model does not
/// enforce bounds or define how offsets are measured for every possible source
/// encoding. Parsers and renderers should agree on the same indexing convention
/// before exchanging anchors.
final class ChordAnchor {
  /// Creates an anchor for [chord] at [offset].
  ChordAnchor({required this.chord, required this.offset});

  /// The chord that should be associated with the lyric position.
  final Chord chord;

  /// The position of [chord] within the owning lyric line.
  ///
  /// No validation is performed here. A negative offset, or an offset beyond the
  /// lyric text length, is possible unless rejected by the code that constructs
  /// the anchor.
  final int offset;
}
