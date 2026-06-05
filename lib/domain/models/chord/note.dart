enum Note {
  cFlat(11, 'Cb'),
  c(0, 'C'),
  cSharp(1, 'C#'),

  dFlat(1, 'Db'),
  d(2, 'D'),
  dSharp(3, 'D#'),

  eFlat(3, 'Eb'),
  e(4, 'E'),
  eSharp(5, 'E#'),

  fFlat(4, 'Fb'),
  f(5, 'F'),
  fSharp(6, 'F#'),

  gFlat(6, 'Gb'),
  g(7, 'G'),
  gSharp(8, 'G#'),

  aFlat(8, 'Ab'),
  a(9, 'A'),
  aSharp(10, 'A#'),

  bFlat(10, 'Bb'),
  b(11, 'B'),
  bSharp(0, 'B#');

  final int semitone;
  final String symbol;

  const Note(this.semitone, this.symbol);
}
