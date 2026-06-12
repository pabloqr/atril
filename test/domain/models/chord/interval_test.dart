import 'package:atril/domain/models/chord/interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes every supported interval as an enum value', () {
    expect(Interval.values, hasLength(26));
    expect(Interval.values, containsAll([Interval.perfectUnison, Interval.perfectOctave]));
  });

  group('Interval.lookup', () {
    test('maps frets to canonical intervals', () {
      final expected = [
        Interval.perfectUnison,
        Interval.minorSecond,
        Interval.majorSecond,
        Interval.minorThird,
        Interval.majorThird,
        Interval.perfectFourth,
        Interval.augmentedFourth,
        Interval.perfectFifth,
        Interval.minorSixth,
        Interval.majorSixth,
        Interval.minorSeventh,
        Interval.majorSeventh,
        Interval.perfectOctave,
      ];

      for (var fret = 0; fret < expected.length; fret++) {
        expect(Interval.lookup[fret], same(expected[fret]), reason: 'capo fret $fret');
      }
    });

    test('returns null outside the supported octave', () {
      expect(Interval.lookup[-1], isNull);
      expect(Interval.lookup[13], isNull);
    });

    test('is unmodifiable', () {
      expect(() => Interval.lookup[0] = Interval.augmentedUnison, throwsUnsupportedError);
    });
  });
}
