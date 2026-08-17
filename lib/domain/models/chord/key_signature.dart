import 'package:atril/domain/models/chord/accidental.dart';
import 'package:atril/domain/models/chord/key_mode.dart';
import 'package:atril/domain/models/chord/note.dart';

enum KeySignature(final Note tonic, final KeyMode mode, final Accidental accidentalFamily, final int accidentalCount) {
  cMajor(Note.c, KeyMode.major, Accidental.natural, 0),
  aMinor(Note.a, KeyMode.minor, Accidental.natural, 0),

  gMajor(Note.g, KeyMode.major, Accidental.sharp, 1),
  eMinor(Note.e, KeyMode.minor, Accidental.sharp, 1),

  dMajor(Note.d, KeyMode.major, Accidental.sharp, 2),
  bMinor(Note.b, KeyMode.minor, Accidental.sharp, 2),

  aMajor(Note.a, KeyMode.major, Accidental.sharp, 3),
  fSharpMinor(Note.fSharp, KeyMode.minor, Accidental.sharp, 3),

  eMajor(Note.e, KeyMode.major, Accidental.sharp, 4),
  cSharpMinor(Note.cSharp, KeyMode.minor, Accidental.sharp, 4),

  bMajor(Note.b, KeyMode.major, Accidental.sharp, 5),
  gSharpMinor(Note.gSharp, KeyMode.minor, Accidental.sharp, 5),

  fSharpMajor(Note.fSharp, KeyMode.major, Accidental.sharp, 6),
  dSharpMinor(Note.dSharp, KeyMode.minor, Accidental.sharp, 6),

  cSharpMajor(Note.cSharp, KeyMode.major, Accidental.sharp, 7),
  aSharpMinor(Note.aSharp, KeyMode.minor, Accidental.sharp, 7),

  fMajor(Note.f, KeyMode.major, Accidental.flat, 1),
  dMinor(Note.d, KeyMode.minor, Accidental.flat, 1),

  bFlatMajor(Note.bFlat, KeyMode.major, Accidental.flat, 2),
  gMinor(Note.g, KeyMode.minor, Accidental.flat, 2),

  eFlatMajor(Note.eFlat, KeyMode.major, Accidental.flat, 3),
  cMinor(Note.c, KeyMode.minor, Accidental.flat, 3),

  aFlatMajor(Note.aFlat, KeyMode.major, Accidental.flat, 4),
  fMinor(Note.f, KeyMode.minor, Accidental.flat, 4),

  dFlatMajor(Note.dFlat, KeyMode.major, Accidental.flat, 5),
  bFlatMinor(Note.bFlat, KeyMode.minor, Accidental.flat, 5),

  gFlatMajor(Note.gFlat, KeyMode.major, Accidental.flat, 6),
  eFlatMinor(Note.eFlat, KeyMode.minor, Accidental.flat, 6),

  cFlatMajor(Note.cFlat, KeyMode.major, Accidental.flat, 7),
  aFlatMinor(Note.aFlat, KeyMode.minor, Accidental.flat, 7);

  static final lookup = Map<(Note, KeyMode), KeySignature>.unmodifiable({
    for (final key in values) (key.tonic, key.mode): key,
  });

  @override
  String toString() => '${tonic.symbol}${mode.symbol}';
}
