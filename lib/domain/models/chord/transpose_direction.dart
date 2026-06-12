/// The direction in which an interval is applied.
enum TransposeDirection {
  up,
  down;

  /// A multiplier for applying the direction to a semitone distance.
  int get sign => this == up ? 1 : -1;
}
