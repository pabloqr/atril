import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/data/services/chord/chromatic_transposition.dart';
import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/chord/key_signature.dart';
import 'package:atril/domain/models/song.dart';

/// Transposes notes, chords, and parsed songs by spelled musical intervals.
///
/// The algorithm applies the interval in two dimensions: [Interval.diatonicSteps]
/// selects the destination note letter and [Interval.semitones] selects its
/// pitch class. Combining both preserves interval spelling, for example making
/// an augmented unison from C produce C# rather than Db.
///
/// Atril currently supports only single flats and sharps. [transposeNote]
/// throws [TranspositionException] if a requested spelling would require a
/// double accidental.
final class SongTransposer {
  /// Creates a stateless transposer.
  const SongTransposer();

  /// Returns a song whose lyric-line chord anchors are transposed.
  ///
  /// Lyric text, line order, anchor offsets, non-lyric lines, and parser issues
  /// are preserved. Metadata is rebuilt by the [Song] constructor from the
  /// resulting directive lines; directive values are not transposed.
  Song transposeSong(Song song, ChromaticTransposition transposition) {
    final transposedKey = transposeKey(song.metadata.key, transposition);
    final transposedLines = song.lines
        .map(
          (line) => switch (line) {
            LyricLine(text: final text, chords: final chords) => LyricLine(
              text: text,
              chords: chords
                  .map(
                    (anchor) => ChordAnchor(
                      chord: transposeChord(anchor.chord, transposition, transposedKey),
                      offset: anchor.offset,
                    ),
                  )
                  .toList(),
            ),
            _ => line,
          },
        )
        .toList();

    return Song(lines: transposedLines, issues: song.issues).withKey(transposedKey);
  }

  KeySignature? transposeKey(KeySignature? key, ChromaticTransposition transposition) {
    if (key == null) return null;

    return switch (transposition) {
      BySemitones() => _transposeKeyBySemitones(key, transposition),
      ToKey() => _transposeKeyToKey(key, transposition),
      ByInterval() => _transposeKeyByInterval(key, transposition),
    };
  }

  /// Transposes the root and optional slash bass while preserving the suffix.
  Chord transposeChord(Chord chord, ChromaticTransposition transposition, [KeySignature? targetKey]) {
    return Chord(
      root: transposeNote(chord.root, transposition, targetKey),
      extension: chord.extension,
      bass: chord.bass != null ? transposeNote(chord.bass!, transposition, targetKey) : null,
    );
  }

  /// Transposes [note] by [interval] in [direction].
  ///
  /// First the destination letter is chosen diatonically. The chromatic target
  /// is then calculated and the accidental needed to reconcile the two is
  /// selected. Throws [TranspositionException] when that accidental is outside
  /// the supported flat-natural-sharp range.
  Note transposeNote(Note note, ChromaticTransposition transposition, [KeySignature? targetKey]) {
    return switch (transposition) {
      BySemitones() => _transposeNoteBySemitones(note, transposition, targetKey),
      ToKey() => _transposeNoteToKey(note, transposition),
      ByInterval() => _transposesNoteByInterval(note, transposition, targetKey),
    };
  }

  KeySignature _transposeKeyBySemitones(KeySignature key, BySemitones transposition) {
    final targetSemitone = (key.tonic.semitone + transposition.semitones) % 12;

    final candidateKeys = KeySignature.values
        .where((k) => k.mode == key.mode && k.tonic.semitone == targetSemitone)
        .toList();

    if (candidateKeys.length == 1) return candidateKeys.single;

    final accidentalFamily = switch (transposition.pitchPreference) {
      PitchPreference.sharps => Accidental.sharp,
      PitchPreference.flats => Accidental.flat,
      PitchPreference.automatic => key.accidentalFamily,
    };

    if (accidentalFamily != Accidental.natural) {
      final familyKeys = candidateKeys.where((k) => k.accidentalFamily == accidentalFamily).toList();
      if (familyKeys.isNotEmpty) return familyKeys.single;
    }

    final minAccidentalCount = candidateKeys.map((key) => key.accidentalCount).reduce((a, b) => a < b ? a : b);
    final minAccidentalCountKeys = candidateKeys.where((key) => key.accidentalCount == minAccidentalCount).toList();

    return minAccidentalCountKeys.firstWhere(
      (key) => key.accidentalFamily == Accidental.sharp,
      orElse: () => minAccidentalCountKeys.first,
    );
  }

  KeySignature _transposeKeyToKey(KeySignature key, ToKey transposition) {
    throw UnimplementedError();
  }

  KeySignature _transposeKeyByInterval(KeySignature key, ByInterval transposition) {
    throw UnimplementedError();
  }

  Note _transposeNoteBySemitones(Note note, BySemitones transposition, [KeySignature? targetKey]) {
    final accidentalFamily =
        targetKey?.accidentalFamily ??
        switch (transposition.pitchPreference) {
          PitchPreference.automatic => note.accidental,
          PitchPreference.sharps => Accidental.sharp,
          PitchPreference.flats => Accidental.flat,
        };

    final notes = switch (accidentalFamily) {
      Accidental.flat => Note.flats,
      _ => Note.sharps,
    };

    final semitone = (note.semitone + transposition.semitones) % notes.length;
    return notes[semitone];
  }

  Note _transposeNoteToKey(Note note, ToKey transposition) {
    throw UnimplementedError();
  }

  Note _transposesNoteByInterval(Note note, ByInterval transposition, [KeySignature? targetKey]) {
    // TODO: refactorizar implementación de la transposición (diatónica --> cromática)

    final steps = transposition.interval.diatonicSteps;
    final semitoneShift = transposition.interval.semitones * transposition.direction.sign;

    final newLetter = transposition.direction == TransposeDirection.up
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
      _ => throw TranspositionException(
        'Transposing $note by ${transposition.interval} ${transposition.direction} requires an accidental outside the supported range (offset: $accidentalOffset).',
      ),
    };

    return Note.lookup[(newLetter, accidental)]!;
  }
}
