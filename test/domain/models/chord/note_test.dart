import 'package:atril/domain/models/chord/accidental.dart';
import 'package:atril/domain/models/chord/note.dart';
import 'package:atril/domain/models/chord/note_letter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes every supported spelling as an enum value', () {
    expect(Note.values, hasLength(NoteLetter.values.length * Accidental.values.length));
  });

  group('Note.lookup', () {
    test('maps every letter and accidental to its canonical note', () {
      for (final letter in NoteLetter.values) {
        for (final accidental in Accidental.values) {
          final note = Note.lookup[(letter, accidental)];

          expect(note, isNotNull);
          expect(note!.letter, letter);
          expect(note.accidental, accidental);
        }
      }
    });

    test('is unmodifiable', () {
      expect(() => Note.lookup[(NoteLetter.c, Accidental.natural)] = Note.cSharp, throwsUnsupportedError);
    });
  });

  group('Note.parse', () {
    test('returns canonical enum values', () {
      expect(Note.parse('C#'), same(Note.cSharp));
      expect(Note.parse('db'), same(Note.dFlat));
    });

    test('rejects unsupported spellings', () {
      expect(() => Note.parse('C##'), throwsFormatException);
      expect(() => Note.parse('D\u266d'), throwsFormatException);
    });
  });
}
