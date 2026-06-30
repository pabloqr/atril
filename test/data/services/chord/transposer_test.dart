import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/data/services/chord/transposer.dart';
import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transposer = Transposer();

  group('Transposer.transposeNote', () {
    test('preserves interval spelling when transposing up', () {
      expect(transposer.transposeNote(Note.c, Interval.augmentedUnison, TransposeDirection.up), Note.cSharp);
      expect(transposer.transposeNote(Note.c, Interval.minorSecond, TransposeDirection.up), Note.dFlat);
      expect(transposer.transposeNote(Note.e, Interval.minorSecond, TransposeDirection.up), Note.f);
    });

    test('preserves interval spelling when transposing down', () {
      expect(transposer.transposeNote(Note.c, Interval.minorSecond, TransposeDirection.down), Note.b);
      expect(transposer.transposeNote(Note.c, Interval.augmentedUnison, TransposeDirection.down), Note.cFlat);
      expect(transposer.transposeNote(Note.fSharp, Interval.perfectFifth, TransposeDirection.down), Note.b);
    });

    test('throws when the requested spelling requires double accidentals', () {
      expect(
        () => transposer.transposeNote(Note.cSharp, Interval.augmentedUnison, TransposeDirection.up),
        throwsA(isA<TranspositionException>()),
      );
    });
  });

  group('Transposer.transposeChord', () {
    test('transposes root and slash bass while preserving extension', () {
      final chord = Chord(root: Note.c, extension: 'm7', bass: Note.g);

      final transposed = transposer.transposeChord(chord, Interval.majorSecond, TransposeDirection.up);

      expect(transposed.root, Note.d);
      expect(transposed.extension, 'm7');
      expect(transposed.bass, Note.a);
    });
  });

  group('Transposer.transposeSong', () {
    test('transposes lyric anchors and preserves text, directives, offsets, and issues', () {
      final issue = ParseIssue(
        code: ParseIssueCode.invalidChord,
        severity: ParseIssueSeverity.error,
        message: 'Invalid',
        location: SourceLocation(sourceOffset: 0, lineIndex: 1, position: 1, length: 3),
      );
      final directive = DirectiveLine(
        directive: Directive(name: 'title', value: 'Song'),
      );
      final song = Song(
        lines: [
          directive,
          LyricLine(
            text: 'Hello',
            chords: [ChordAnchor(chord: Chord(root: Note.c), offset: 2)],
          ),
        ],
        issues: [issue],
      );

      final transposed = transposer.transposeSong(song, Interval.perfectFifth, TransposeDirection.up);
      final line = transposed.lines[1] as LyricLine;

      expect(transposed.lines.first, same(directive));
      expect(line.text, 'Hello');
      expect(line.chords.single.offset, 2);
      expect(line.chords.single.chord.root, Note.g);
      expect(transposed.issues.single, same(issue));
    });
  });
}
