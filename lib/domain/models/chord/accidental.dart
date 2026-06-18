/// A single accidental applied to a diatonic note letter.
///
/// Atril deliberately supports only flats, naturals, and sharps. Double
/// accidentals are outside the current chord notation subset.
enum Accidental {
  flat,
  natural,
  sharp;

  /// The chromatic displacement from the natural note in semitones.
  int get semitoneOffset => switch (this) {
    Accidental.flat => -1,
    Accidental.natural => 0,
    Accidental.sharp => 1,
  };

  /// The ASCII notation used when serializing the accidental.
  String get symbol => switch (this) {
    Accidental.flat => 'b',
    Accidental.natural => '',
    Accidental.sharp => '#',
  };
}
