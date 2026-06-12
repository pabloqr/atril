import 'package:atril/domain/models/song/chord_anchor.dart';
import 'package:atril/domain/models/song/directive.dart';

/// A single logical line in a song document.
///
/// Song content is modeled as a sealed hierarchy so consumers can exhaustively
/// handle every supported line kind. The current line kinds are:
///
/// - [DirectiveLine], for structured non-lyric instructions.
/// - [LyricLine], for lyric text and positioned chords.
/// - [EmptyLine], for intentional blank lines.
///
/// A [Line] is logical rather than visual. Renderers may wrap, collapse, or
/// otherwise transform lines when presenting a song.
sealed class Line {
  /// Creates a line variant.
  const Line();
}

/// A line that contains a structured directive.
///
/// The type parameter [T] is the payload type carried by the underlying
/// [Directive]. This keeps the line model independent from any single source
/// format or parser strategy.
final class DirectiveLine<T> extends Line {
  /// Creates a directive line.
  DirectiveLine({required this.directive});

  /// The directive represented by this line.
  final Directive<T> directive;

  /// The directive name converted to lowercase.
  ///
  /// This is a convenience for case-insensitive comparisons. It uses Dart's
  /// standard [String.toLowerCase] behavior and does not perform alias
  /// resolution, trimming, or locale-specific normalization.
  String get name => directive.name;

  /// The optional directive payload, forwarded from [directive].
  T? get value => directive.value;
}

/// A line containing lyric text and zero or more chord anchors.
///
/// [text] is the lyric content after chord markup has been separated from the
/// line. [chords] contains the chords that should be associated with positions
/// in that text.
final class LyricLine extends Line {
  /// Creates a lyric line with its [text] and positioned [chords].
  LyricLine({required this.text, this.chords = const []});

  /// The lyric text for this line.
  ///
  /// Chord symbols are not expected to be embedded in this string once they have
  /// been parsed into [chords].
  final String text;

  /// Chords positioned against [text].
  ///
  /// The list is stored as received. This class does not sort anchors, validate
  /// offsets, remove duplicates, or make a defensive copy.
  final List<ChordAnchor> chords;
}

/// An intentional blank line in a song document.
///
/// Empty lines are represented explicitly so parsers can preserve spacing and
/// renderers can distinguish an omitted line from a deliberate blank separator.
final class EmptyLine extends Line {}
