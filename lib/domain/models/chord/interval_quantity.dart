/// The diatonic size component of a named musical interval.
enum IntervalQuantity(
  /// The number of note-letter transitions from the starting note.
  ///
  /// For example, a third spans two transitions: C-D-E.
  final int diatonicSteps,
) {
  unison(0),
  second(1),
  third(2),
  fourth(3),
  fifth(4),
  sixth(5),
  seventh(6),
  octave(7);
}
