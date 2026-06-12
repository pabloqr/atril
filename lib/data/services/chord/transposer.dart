import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/song.dart';

/// Transposes notes, chords, and parsed songs by spelled musical intervals.
///
/// The algorithm applies the interval in two dimensions: [Interval.diatonicSteps]
/// selects the destination note letter and [Interval.semitones] selects its
/// pitch class. Combining both preserves interval spelling, for example making
/// an augmented unison from C produce C# rather than Db.
///
/// Atril currently supports only single flats and sharps. [transposeNote]
/// throws [ArgumentError] if a requested spelling would require a double
/// accidental.
final class Transposer {
  /// Creates a stateless transposer.
  const Transposer();

  /// Returns a song whose lyric-line chord anchors are transposed.
  ///
  /// Lyric text, line order, anchor offsets, non-lyric lines, and parser issues
  /// are preserved. Metadata is rebuilt by the [Song] constructor from the
  /// resulting directive lines; directive values are not transposed.
  Song transposeSong(Song song, Interval interval, TransposeDirection direction) {
    final transposedLines = song.lines.map((line) {
      if (line is LyricLine) {
        return LyricLine(
          text: line.text,
          chords: line.chords
              .map(
                (anchor) =>
                    ChordAnchor(chord: transposeChord(anchor.chord, interval, direction), offset: anchor.offset),
              )
              .toList(),
        );
      }
      return line;
    }).toList();

    return Song(lines: transposedLines, issues: song.issues.toList());
  }

  /// Transposes the root and optional slash bass while preserving the suffix.
  Chord transposeChord(Chord chord, Interval interval, TransposeDirection direction) => Chord(
    root: transposeNote(chord.root, interval, direction),
    extension: chord.extension,
    bass: chord.bass != null ? transposeNote(chord.bass!, interval, direction) : null,
  );

  /// Transposes [note] by [interval] in [direction].
  ///
  /// First the destination letter is chosen diatonically. The chromatic target
  /// is then calculated and the accidental needed to reconcile the two is
  /// selected. Throws [ArgumentError] when that accidental is outside the
  /// supported flat-natural-sharp range.
  Note transposeNote(Note note, Interval interval, TransposeDirection direction) {
    final steps = interval.diatonicSteps;
    final semitoneShift = interval.semitones * direction.sign;

    final newLetter = direction == TransposeDirection.up
        ? note.letter.plusDiatonic(steps)
        : note.letter.plusDiatonic(NoteLetter.values.length - steps);

    final targetSemitone = (note.semitone + semitoneShift) % 12;

    // Express the target relative to the destination natural note. Modulo 12
    // represents a flat as 11, allowing the switch to stay pitch-class based.
    final accidentalOffset = (targetSemitone - newLetter.naturalSemitone + 12) % 12;

    final accidental = switch (accidentalOffset) {
      0 => Accidental.natural,
      1 => Accidental.sharp,
      11 => Accidental.flat,
      _ => throw ArgumentError(
        'Transposing $note by $interval $direction requires an accidental '
        'outside the supported range (offset: $accidentalOffset).',
      ),
    };

    return Note.lookup[(newLetter, accidental)]!;
  }
}
