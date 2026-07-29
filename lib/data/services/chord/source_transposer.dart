import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/core/utils/patterns.dart';
import 'package:atril/data/services/chord/chord_codec.dart';
import 'package:atril/data/services/chord/song_transposer.dart';
import 'package:atril/domain/models/chord.dart';

final class SourceTransposer {
  const SourceTransposer();

  final _songTransposer = const SongTransposer();

  /// Transposes every valid inline chord in [source].
  ///
  /// Directive lines, invalid chord markers, lyric text, and line endings are
  /// preserved. A [TranspositionException] from a valid chord is allowed to
  /// propagate so callers never receive a partially transposed source.
  String transposeSource(String source, Interval interval, TransposeDirection direction) {
    final buffer = StringBuffer();
    var lineStart = 0;

    for (final lineEnding in Patterns.lineEndings.allMatches(source)) {
      buffer
        ..write(_transposeLine(source.substring(lineStart, lineEnding.start), interval, direction))
        ..write(lineEnding.group(0));
      lineStart = lineEnding.end;
    }

    buffer.write(_transposeLine(source.substring(lineStart), interval, direction));
    return buffer.toString();
  }

  /// Transposes a chord from its compact source representation.
  String transposeChord(String chordSource, Interval interval, TransposeDirection direction) {
    final chord = chordCodec.decode(chordSource);
    final transposedChord = _songTransposer.transposeChord(chord, interval, direction);
    return chordCodec.encode(transposedChord);
  }

  String _transposeLine(String line, Interval interval, TransposeDirection direction) {
    // SongCodec treats a line beginning with "{" as a directive or malformed
    // directive rather than parsing inline chords from it.
    if (line.trimLeft().startsWith('{')) return line;

    return line.replaceAllMapped(Patterns.chordInline, (match) {
      final chordSource = match.group(1)!;

      try {
        return '[${transposeChord(chordSource, interval, direction)}]';
      } on FormatException {
        return match.group(0)!;
      }
    });
  }
}
