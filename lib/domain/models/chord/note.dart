import 'package:atril/domain/models/chord/accidental.dart';
import 'package:atril/domain/models/chord/note_letter.dart';

/// A supported spelled musical note composed of a [letter] and [accidental].
///
/// The enum contains every combination of the seven note letters with a flat,
/// natural, or sharp accidental. Spelling remains significant: `C#` and `Db`
/// share a [semitone] but are different values. This distinction is required
/// for interval-aware transposition and faithful chord serialization.
enum Note {
  cFlat(NoteLetter.c, Accidental.flat),
  c(NoteLetter.c, Accidental.natural),
  cSharp(NoteLetter.c, Accidental.sharp),

  dFlat(NoteLetter.d, Accidental.flat),
  d(NoteLetter.d, Accidental.natural),
  dSharp(NoteLetter.d, Accidental.sharp),

  eFlat(NoteLetter.e, Accidental.flat),
  e(NoteLetter.e, Accidental.natural),
  eSharp(NoteLetter.e, Accidental.sharp),

  fFlat(NoteLetter.f, Accidental.flat),
  f(NoteLetter.f, Accidental.natural),
  fSharp(NoteLetter.f, Accidental.sharp),

  gFlat(NoteLetter.g, Accidental.flat),
  g(NoteLetter.g, Accidental.natural),
  gSharp(NoteLetter.g, Accidental.sharp),

  aFlat(NoteLetter.a, Accidental.flat),
  a(NoteLetter.a, Accidental.natural),
  aSharp(NoteLetter.a, Accidental.sharp),

  bFlat(NoteLetter.b, Accidental.flat),
  b(NoteLetter.b, Accidental.natural),
  bSharp(NoteLetter.b, Accidental.sharp);

  /// Creates a supported note with the given spelling.
  const Note(this.letter, this.accidental);

  /// The diatonic note name.
  final NoteLetter letter;

  /// The accidental modifying [letter].
  final Accidental accidental;

  /// The normalized pitch class in the range 0 through 11, where C is zero.
  int get semitone => (letter.naturalSemitone + accidental.semitoneOffset) % 12;

  /// The ASCII note spelling used in chord source, such as `C#` or `Eb`.
  String get symbol => '${letter.name.toUpperCase()}${accidental.symbol}';

  /// Canonical lookup by note letter and accidental.
  ///
  /// Every combination represented by [NoteLetter] and [Accidental] is present,
  /// so callers using those enum types receive a non-null value. The record key
  /// makes the spelling dimension explicit and avoids collapsing enharmonic
  /// notes that share [semitone].
  static final lookup = Map<(NoteLetter, Accidental), Note>.unmodifiable({
    for (final note in values) (note.letter, note.accidental): note,
  });

  /// Parses a complete ASCII note symbol.
  ///
  /// The letter is case-insensitive, while the only accepted accidentals are
  /// `#` and lowercase `b`. Throws [FormatException] for empty input, unknown
  /// letters, unsupported accidentals, or trailing characters.
  static Note parse(String symbol) {
    if (symbol.isEmpty) throw FormatException('Empty note symbol.', symbol);

    final letterChar = symbol[0].toUpperCase();
    final accidentalStr = symbol.length > 1 ? symbol.substring(1) : '';

    final noteLetter = NoteLetter.values.firstWhere(
      (letter) => letter.name.toUpperCase() == letterChar,
      orElse: () => throw FormatException('Unknown note letter', symbol),
    );

    final accidental = switch (accidentalStr) {
      '' => Accidental.natural,
      '#' => Accidental.sharp,
      'b' => Accidental.flat,
      _ => throw FormatException('Unknown accidental', symbol),
    };

    return lookup[(noteLetter, accidental)]!;
  }

  @override
  String toString() => symbol;
}
