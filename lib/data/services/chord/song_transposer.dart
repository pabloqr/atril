import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/data/services/chord/chromatic_transposition.dart';
import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/chord/key_signature.dart';
import 'package:atril/domain/models/song.dart';

/// Applies chromatic transposition requests to notes, chords, and parsed songs.
///
/// A [ChromaticTransposition] selects how the destination is expressed. The
/// transposer first derives the target key when the source song has one, then
/// uses that key to choose consistent enharmonic spellings for chord roots and
/// slash bass notes.
final class SongTransposer {
  /// Creates a stateless transposer.
  const SongTransposer();

  /// Returns a song whose lyric-line chord anchors are transposed.
  ///
  /// Lyric text, line order, anchor offsets, non-key directives, and parser
  /// issues are preserved. When the song has a key, its key directive is
  /// replaced with the result of [transposeKey].
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

  /// Returns the target key produced by [transposition].
  ///
  /// Returns `null` when [key] is absent. Semitone transposition preserves the
  /// key mode and selects an enharmonic key according to the request's pitch
  /// preference. Other request modes may throw [UnimplementedError] until their
  /// algorithms are implemented.
  KeySignature? transposeKey(KeySignature? key, ChromaticTransposition transposition) {
    if (key == null) return null;

    return switch (transposition) {
      BySemitones() => _transposeKeyBySemitones(key, transposition),
      ToKey() => _transposeKeyToKey(key, transposition),
      ByInterval() => _transposeKeyByInterval(key, transposition),
    };
  }

  /// Transposes a chord root and optional slash bass while preserving its
  /// extension.
  ///
  /// When provided, [targetKey] determines the enharmonic spelling of notes.
  Chord transposeChord(Chord chord, ChromaticTransposition transposition, [KeySignature? targetKey]) {
    return Chord(
      root: transposeNote(chord.root, transposition, targetKey),
      extension: chord.extension,
      bass: chord.bass != null ? transposeNote(chord.bass!, transposition, targetKey) : null,
    );
  }

  /// Transposes [note] according to [transposition].
  ///
  /// When [targetKey] is available, its accidental family takes precedence over
  /// the fallback pitch preference carried by the request.
  ///
  /// Request modes whose algorithms are not yet available may throw
  /// [UnimplementedError]. The current interval implementation may throw
  /// [TranspositionException] when the requested spelling would require an
  /// unsupported accidental.
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
    // TODO: Replace the temporary diatonic implementation with chromatic transposition.

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
