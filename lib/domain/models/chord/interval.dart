import 'package:atril/domain/models/chord/interval_qualifier.dart';
import 'package:atril/domain/models/chord/interval_quantity.dart';

/// A supported musical interval with both diatonic and chromatic distance.
///
/// The enum is the closed set of intervals currently understood by Atril.
/// Keeping both distances allows transposition to preserve correct note
/// spelling instead of selecting an enharmonic note solely by pitch class.
/// Semitone values follow the standard chromatic distances:
///
/// | Interval            | Semitones |
/// |---------------------|-----------|
/// | Perfect unison      | 0         |
/// | Augmented unison    | 1         |
/// | Diminished second   | 0         |
/// | Minor second        | 1         |
/// | Major second        | 2         |
/// | Augmented second    | 3         |
/// | Diminished third    | 2         |
/// | Minor third         | 3         |
/// | Major third         | 4         |
/// | Augmented third     | 5         |
/// | Diminished fourth   | 4         |
/// | Perfect fourth      | 5         |
/// | Augmented fourth    | 6         |
/// | Diminished fifth    | 6         |
/// | Perfect fifth       | 7         |
/// | Augmented fifth     | 8         |
/// | Diminished sixth    | 7         |
/// | Minor sixth         | 8         |
/// | Major sixth         | 9         |
/// | Augmented sixth     | 10        |
/// | Diminished seventh  | 9         |
/// | Minor seventh       | 10        |
/// | Major seventh       | 11        |
/// | Augmented seventh   | 12        |
/// | Diminished octave   | 11        |
/// | Perfect octave      | 12        |
enum Interval {
  perfectUnison(IntervalQuantity.unison, IntervalQualifier.perfect, 0),
  augmentedUnison(IntervalQuantity.unison, IntervalQualifier.augmented, 1),

  diminishedSecond(IntervalQuantity.second, IntervalQualifier.diminished, 0),
  minorSecond(IntervalQuantity.second, IntervalQualifier.minor, 1),
  majorSecond(IntervalQuantity.second, IntervalQualifier.major, 2),
  augmentedSecond(IntervalQuantity.second, IntervalQualifier.augmented, 3),

  diminishedThird(IntervalQuantity.third, IntervalQualifier.diminished, 2),
  minorThird(IntervalQuantity.third, IntervalQualifier.minor, 3),
  majorThird(IntervalQuantity.third, IntervalQualifier.major, 4),
  augmentedThird(IntervalQuantity.third, IntervalQualifier.augmented, 5),

  diminishedFourth(IntervalQuantity.fourth, IntervalQualifier.diminished, 4),
  perfectFourth(IntervalQuantity.fourth, IntervalQualifier.perfect, 5),
  augmentedFourth(IntervalQuantity.fourth, IntervalQualifier.augmented, 6),

  diminishedFifth(IntervalQuantity.fifth, IntervalQualifier.diminished, 6),
  perfectFifth(IntervalQuantity.fifth, IntervalQualifier.perfect, 7),
  augmentedFifth(IntervalQuantity.fifth, IntervalQualifier.augmented, 8),

  diminishedSixth(IntervalQuantity.sixth, IntervalQualifier.diminished, 7),
  minorSixth(IntervalQuantity.sixth, IntervalQualifier.minor, 8),
  majorSixth(IntervalQuantity.sixth, IntervalQualifier.major, 9),
  augmentedSixth(IntervalQuantity.sixth, IntervalQualifier.augmented, 10),

  diminishedSeventh(IntervalQuantity.seventh, IntervalQualifier.diminished, 9),
  minorSeventh(IntervalQuantity.seventh, IntervalQualifier.minor, 10),
  majorSeventh(IntervalQuantity.seventh, IntervalQualifier.major, 11),
  augmentedSeventh(IntervalQuantity.seventh, IntervalQualifier.augmented, 12),

  diminishedOctave(IntervalQuantity.octave, IntervalQualifier.diminished, 11),
  perfectOctave(IntervalQuantity.octave, IntervalQualifier.perfect, 12);

  /// Creates a supported interval with its diatonic and chromatic dimensions.
  const Interval(this.quantity, this.qualifier, this.semitones);

  /// The interval's ordinal size, such as a third or fifth.
  final IntervalQuantity quantity;

  /// The interval's quality, such as minor, perfect, or augmented.
  final IntervalQualifier qualifier;

  /// The interval's chromatic distance in semitones.
  final int semitones;

  /// Canonical interval lookup by capo fret or chromatic semitone distance.
  ///
  /// Keys cover one octave, from `0` ([perfectUnison]) through `12`
  /// ([perfectOctave]). Enharmonically ambiguous distances use Atril's
  /// preferred simple spelling; in particular, six semitones map to
  /// [augmentedFourth].
  ///
  /// A capo raises sounding pitch by the interval found at its fret number. To
  /// preserve sounding pitch when adding a capo, transpose the written chords
  /// downward by the returned interval. Indexing the map with a value outside
  /// `0..12` returns `null`.
  static final lookup = Map<int, Interval>.unmodifiable({
    0: perfectUnison,
    1: minorSecond,
    2: majorSecond,
    3: minorThird,
    4: majorThird,
    5: perfectFourth,
    6: augmentedFourth,
    7: perfectFifth,
    8: minorSixth,
    9: majorSixth,
    10: minorSeventh,
    11: majorSeventh,
    12: perfectOctave,
  });

  /// The number of note-letter transitions implied by [quantity].
  int get diatonicSteps => quantity.diatonicSteps;

  @override
  String toString() => '${quantity.name} ${qualifier.name}';
}
