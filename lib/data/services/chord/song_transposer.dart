import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/data/services/chord/chromatic_transposition.dart';
import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/chord/key_mode.dart';
import 'package:atril/domain/models/chord/key_signature.dart';
import 'package:atril/domain/models/chord/resolved_transposition.dart';
import 'package:atril/domain/models/song.dart';

/// Applies chromatic transposition requests to notes, chords, and parsed songs.
///
/// A [ChromaticTransposition] selects how the destination is expressed. The
/// transposer first derives the target key when the source song has one, then
/// uses that key to choose consistent enharmonic spellings for chord roots and
/// slash bass notes.
final class const SongTransposer() {
  /// Converts [transposition] into the diatonic and chromatic movement used by
  /// the transposition operations.
  ///
  /// When [sourceKey] is available, the result includes an enharmonically
  /// appropriate `targetKey`. A `ToKey` request requires
  /// [sourceKey] and throws [TranspositionException] when it is absent.
  ResolvedTransposition resolve(ChromaticTransposition transposition, {KeySignature? sourceKey}) {
    return switch (transposition) {
      BySemitones(:final semitones, :final pitchPreference) => _resolveSemitones(semitones, pitchPreference, sourceKey),
      ToKey(:final key) => _resolveToKey(key, sourceKey),
      ByInterval(:final interval, :final direction, :final pitchPreference) => _resolveInterval(
        interval,
        direction,
        pitchPreference,
        sourceKey,
      ),
    };
  }

  /// Returns a song whose lyric-line chord anchors are transposed.
  ///
  /// Lyric text, line order, anchor offsets, non-key directives, and parser
  /// issues are preserved. When the song has a key, the returned song uses the
  /// resolved destination key.
  Song transposeSong(Song song, ChromaticTransposition transposition) {
    final resolvedTransposition = resolve(transposition, sourceKey: song.metadata.key);

    // final transposedKey = transposeKey(song.metadata.key, transposition);
    final transposedLines = song.lines
        .map(
          (line) => switch (line) {
            LyricLine(text: final text, chords: final chords) => LyricLine(
              text: text,
              chords: chords
                  .map(
                    (anchor) => ChordAnchor(
                      chord: transposeChordResolved(anchor.chord, resolvedTransposition),
                      offset: anchor.offset,
                    ),
                  )
                  .toList(),
            ),
            _ => line,
          },
        )
        .toList();

    return Song(lines: transposedLines, issues: song.issues).withKey(resolvedTransposition.targetKey);
  }

  /// Transposes a chord root and optional slash bass while preserving its
  /// extension.
  ///
  /// When provided, `sourceKey` determines the enharmonic spelling of notes.
  Chord transposeChord(Chord chord, ChromaticTransposition transposition, [KeySignature? sourceKey]) {
    return transposeChordResolved(chord, resolve(transposition, sourceKey: sourceKey));
  }

  /// Transposes [chord] using a previously [resolve]d [transposition].
  ///
  /// This avoids resolving the same request repeatedly when several chords
  /// share a source key. The chord extension is retained verbatim; only the
  /// root and optional slash bass are transposed.
  Chord transposeChordResolved(Chord chord, ResolvedTransposition transposition) {
    return Chord(
      root: _transposeNoteResolved(chord.root, transposition),
      extension: chord.extension,
      bass: chord.bass == null ? null : _transposeNoteResolved(chord.bass!, transposition),
    );
  }

  /// Transposes [note] according to [transposition].
  ///
  /// When `sourceKey` is available, its accidental family takes precedence over
  /// the fallback pitch preference carried by the request.
  ///
  /// A `ToKey` request without a source key throws [TranspositionException].
  /// The transposer uses an enharmonic fallback when the requested spelling
  /// would otherwise need an unsupported accidental.
  Note transposeNote(Note note, ChromaticTransposition transposition, [KeySignature? sourceKey]) {
    return _transposeNoteResolved(note, resolve(transposition, sourceKey: sourceKey));
  }

  /// Resolves a semitone displacement, deriving a target key when possible.
  ///
  /// Without [sourceKey], the canonical diatonic distance and the requested
  /// accidental family determine the spelling preference.
  ResolvedTransposition _resolveSemitones(int semitones, PitchPreference pitchPreference, KeySignature? sourceKey) {
    if (sourceKey == null) {
      return ResolvedTransposition(
        diatonicSteps: _canonicalDiatonicSteps(semitones, pitchPreference),
        chromaticSemitones: semitones,
        preferredAccidentalFamily: _preferredFamily(pitchPreference),
      );
    }

    final targetKey = _keyFor(
      mode: sourceKey.mode,
      semitone: sourceKey.tonic.semitone + semitones,
      preference: pitchPreference,
      fallbackFamily: sourceKey.accidentalFamily,
    );

    return _betweenKeysWithChromaticDistance(sourceKey, targetKey, semitones);
  }

  /// Resolves the closest signed movement from [sourceKey] to [targetKey].
  ///
  /// The chromatic distance is normalized to at most six semitones in either
  /// direction. A target-key request cannot be resolved without a source key.
  ResolvedTransposition _resolveToKey(KeySignature targetKey, KeySignature? sourceKey) {
    if (sourceKey == null) {
      throw const TranspositionException('No se puede transponer a una tonalidad sin una tonalidad de origen.');
    }

    var diatonicSteps = targetKey.tonic.letter.diatonicIndex - sourceKey.tonic.letter.diatonicIndex;
    var chromaticSemitones = targetKey.tonic.semitone - sourceKey.tonic.semitone;

    while (chromaticSemitones > 6) {
      chromaticSemitones -= 12;
      diatonicSteps -= 7;
    }
    while (chromaticSemitones < -6) {
      chromaticSemitones += 12;
      diatonicSteps += 7;
    }

    return ResolvedTransposition(
      diatonicSteps: diatonicSteps,
      chromaticSemitones: chromaticSemitones,
      targetKey: targetKey,
      preferredAccidentalFamily: targetKey.accidentalFamily,
    );
  }

  /// Resolves a named interval into signed diatonic and chromatic distances.
  ///
  /// A source key, when present, is shifted by the chromatic distance to
  /// derive a target key with the requested spelling preference.
  ResolvedTransposition _resolveInterval(
    Interval interval,
    TransposeDirection direction,
    PitchPreference preference,
    KeySignature? sourceKey,
  ) {
    final chromaticSemitones = interval.semitones * direction.sign;
    final diatonicSteps = interval.diatonicSteps * direction.sign;

    final targetKey = sourceKey == null
        ? null
        : _keyFor(
            mode: sourceKey.mode,
            semitone: sourceKey.tonic.semitone + chromaticSemitones,
            preference: preference,
            fallbackFamily: sourceKey.accidentalFamily,
          );

    return ResolvedTransposition(
      diatonicSteps: diatonicSteps,
      chromaticSemitones: chromaticSemitones,
      targetKey: targetKey,
      preferredAccidentalFamily: targetKey?.accidentalFamily,
    );
  }

  /// Returns the accidental family explicitly requested by [preference].
  ///
  /// Automatic preference has no fixed family and is represented by `null`.
  Accidental? _preferredFamily(PitchPreference preference) {
    return switch (preference) {
      PitchPreference.sharps => Accidental.sharp,
      PitchPreference.flats => Accidental.flat,
      PitchPreference.automatic => null,
    };
  }

  /// Creates a transposition between two keys with [chromaticDistance].
  ///
  /// The supplied distance preserves octave displacement, while the key names
  /// determine the diatonic letter movement and accidental family.
  ResolvedTransposition _betweenKeysWithChromaticDistance(
    KeySignature sourceKey,
    KeySignature targetKey,
    int chromaticDistance,
  ) {
    final tonicChromaticDifference = targetKey.tonic.semitone - sourceKey.tonic.semitone;
    final octaves = (chromaticDistance - tonicChromaticDifference) ~/ 12;

    return ResolvedTransposition(
      diatonicSteps: targetKey.tonic.letter.diatonicIndex - sourceKey.tonic.letter.diatonicIndex + (octaves * 7),
      chromaticSemitones: chromaticDistance,
      targetKey: targetKey,
      preferredAccidentalFamily: targetKey.accidentalFamily,
    );
  }

  /// Finds the supported key with [mode] and pitch class [semitone].
  ///
  /// It first honors [preference], using [fallbackFamily] for automatic
  /// preference. If no matching spelling exists, it chooses the candidate with
  /// the fewest accidentals.
  KeySignature _keyFor({
    required KeyMode mode,
    required int semitone,
    required PitchPreference preference,
    required Accidental fallbackFamily,
  }) {
    final candidates = KeySignature.values.where((key) => key.mode == mode && key.tonic.semitone == semitone % 12);

    final preferredFamily = switch (preference) {
      PitchPreference.sharps => Accidental.sharp,
      PitchPreference.flats => Accidental.flat,
      PitchPreference.automatic => fallbackFamily,
    };

    return candidates.firstWhere(
      (key) => key.accidentalFamily == preferredFamily,
      orElse: () =>
          candidates.reduce((best, current) => current.accidentalCount < best.accidentalCount ? current : best),
    );
  }

  /// Returns the conventional diatonic movement for a semitone distance.
  ///
  /// The lookup favors sharps for automatic preference and includes whole
  /// octaves in the resulting signed distance.
  int _canonicalDiatonicSteps(int semitones, PitchPreference preference) {
    final sign = semitones < 0 ? -1 : 1;
    final magnitude = semitones.abs();
    final octaves = magnitude ~/ 12;
    final remainder = magnitude % 12;

    final steps = switch (preference) {
      PitchPreference.sharps || PitchPreference.automatic => const [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6][remainder],
      PitchPreference.flats => const [0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6][remainder],
    };

    return sign * ((octaves * 7) + steps);
  }

  /// Applies [transposition] to [note], preserving its intended letter where
  /// the supported accidental set permits it.
  ///
  /// When the exact spelling requires an unsupported accidental, this method
  /// delegates to [_clampEnharmonic] to select a simple equivalent.
  Note _transposeNoteResolved(Note note, ResolvedTransposition transposition) {
    final intendedLetter = note.letter.plusDiatonic(transposition.diatonicSteps);

    final targetSemitone = (note.semitone + transposition.chromaticSemitones) % 12;

    final accidentalOffset = (targetSemitone - intendedLetter.naturalSemitone + 12) % 12;

    final exactAccidental = switch (accidentalOffset) {
      0 => Accidental.natural,
      1 => Accidental.sharp,
      11 => Accidental.flat,
      _ => null,
    };

    if (exactAccidental != null) {
      return Note.lookup[(intendedLetter, exactAccidental)]!;
    }

    return _clampEnharmonic(targetSemitone, intendedLetter, transposition.preferredAccidentalFamily);
  }

  /// Selects the best supported spelling for [semitone].
  ///
  /// Candidates are ranked by [_enharmonicScore] to favor natural notes, the
  /// requested accidental family, and proximity to [intendedLetter].
  Note _clampEnharmonic(int semitone, NoteLetter intendedLetter, Accidental? preferredFamily) {
    final candidates = Note.values.where((note) => note.semitone == semitone).toList()
      ..sort((a, b) {
        final scoreA = _enharmonicScore(a, intendedLetter, preferredFamily);
        final scoreB = _enharmonicScore(b, intendedLetter, preferredFamily);

        return scoreA.compareTo(scoreB);
      });

    if (candidates.isEmpty) {
      throw TranspositionException('No existe una grafía simple para el semitono $semitone.');
    }

    return candidates.first;
  }

  /// Scores an enharmonic [candidate] for selection by [_clampEnharmonic].
  ///
  /// Lower scores favor natural notes, then [preferredFamily], then the note
  /// letter nearest to [intendedLetter].
  int _enharmonicScore(Note candidate, NoteLetter intendedLetter, Accidental? preferredFamily) {
    final accidentalCost = candidate.accidental == Accidental.natural ? 0 : 100;

    final familyCost =
        preferredFamily == null || candidate.accidental == Accidental.natural || candidate.accidental == preferredFamily
        ? 0
        : 10;

    final rawDistance = (candidate.letter.diatonicIndex - intendedLetter.diatonicIndex).abs();
    final letterDistance = rawDistance < 4 ? rawDistance : 7 - rawDistance;

    return accidentalCost + familyCost + letterDistance;
  }
}
