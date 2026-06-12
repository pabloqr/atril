import 'package:atril/data/services/chord/chord_codec.dart';
import 'package:atril/domain/models/chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChordCodec', () {
    test('decodes chord notation using Note.parse', () {
      final chord = chordCodec.decode('C#m7/Gb');

      expect(chord.root, Note.cSharp);
      expect(chord.extension, 'm7');
      expect(chord.bass, Note.gFlat);
    });

    test('encodes chord notation using note symbols', () {
      final chord = Chord(root: Note.eFlat, extension: 'maj7', bass: Note.bFlat);

      expect(chordCodec.encode(chord), 'Ebmaj7/Bb');
    });

    test('round-trips natural, sharp, and flat notes', () {
      for (final notation in ['C', 'F#7', 'Bbm/F']) {
        expect(chordCodec.encode(chordCodec.decode(notation)), notation);
      }
    });

    test('rejects invalid chord notation', () {
      expect(() => chordCodec.decode('H7'), throwsFormatException);
    });
  });
}
