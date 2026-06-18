/// A natural note name and its position in chromatic and diatonic space.
enum NoteLetter {
  c(0, 0),
  d(2, 1),
  e(4, 2),
  f(5, 3),
  g(7, 4),
  a(9, 5),
  b(11, 6);

  /// Creates a note letter at [naturalSemitone] and [diatonicIndex].
  const NoteLetter(this.naturalSemitone, this.diatonicIndex);

  /// The pitch class of the natural note, where C is zero.
  final int naturalSemitone;

  /// The zero-based position in the C-D-E-F-G-A-B cycle.
  final int diatonicIndex;

  /// Returns the note letter [steps] forward in the diatonic cycle.
  ///
  /// Values wrap after B. Callers that need to move down can pass the
  /// equivalent positive distance, as the transposition service does.
  NoteLetter plusDiatonic(int steps) {
    final values = NoteLetter.values;
    return values[(diatonicIndex + steps) % values.length];
  }
}
