import 'package:atril/data/services/song/song_codec.dart';
import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongCodec.decode', () {
    test('normalizes line endings and preserves empty lines', () {
      final song = songCodec.decode('{title: Song}\r\n\rVerse');

      expect(song.lines, hasLength(3));
      expect(song.lines[0], isA<DirectiveLine>().having((line) => line.value, 'value', 'Song'));
      expect(song.lines[1], isA<EmptyLine>());
      expect(song.lines[2], isA<LyricLine>().having((line) => line.text, 'text', 'Verse'));
    });

    test('extracts inline chords and lyric offsets', () {
      final song = songCodec.decode('[C]Amazing [F]grace');
      final line = song.lines.single as LyricLine;

      expect(line.text, 'Amazing grace');
      expect(line.chords, hasLength(2));
      expect(line.chords[0].chord.root, Note.c);
      expect(line.chords[0].offset, 0);
      expect(line.chords[1].chord.root, Note.f);
      expect(line.chords[1].offset, 8);
      expect(song.issues, isEmpty);
    });

    test('keeps malformed source text and reports recoverable issues', () {
      final song = songCodec.decode('{title: Broken\nLine with ] bracket\nLine with [ chord');

      expect(song.lines, hasLength(3));
      expect(song.lines[0], isA<LyricLine>().having((line) => line.text, 'text', '{title: Broken'));
      expect(song.lines[1], isA<LyricLine>().having((line) => line.text, 'text', 'Line with ] bracket'));
      expect(song.lines[2], isA<LyricLine>().having((line) => line.text, 'text', 'Line with [ chord'));
      expect(song.issues.map((issue) => issue.code), [
        ParseIssueCode.malformedDirective,
        ParseIssueCode.malformedChord,
        ParseIssueCode.malformedChord,
      ]);
      expect(song.issues[0].location.lineIndex, 1);
      expect(song.issues[1].location.position, 11);
      expect(song.issues[2].location.length, 7);
    });

    test('retains invalid chord markers as lyric text', () {
      final song = songCodec.decode('Play [H7] here and [] there');
      final line = song.lines.single as LyricLine;

      expect(line.text, 'Play [H7] here and [] there');
      expect(line.chords, isEmpty);
      expect(song.issues.map((issue) => issue.code), [ParseIssueCode.invalidChord, ParseIssueCode.invalidChord]);
    });
  });

  group('SongCodec.encode', () {
    test('serializes directives, empty lines, and lyric chords', () {
      final song = Song(
        lines: [
          DirectiveLine(
            directive: Directive(name: 'title', value: 'Song'),
          ),
          DirectiveLine(directive: Directive<String>(name: 'comment')),
          EmptyLine(),
          LyricLine(
            text: 'Amazing grace',
            chords: [
              ChordAnchor(chord: Chord(root: Note.c), offset: 0),
              ChordAnchor(chord: Chord(root: Note.f), offset: 8),
            ],
          ),
        ],
      );

      expect(songCodec.encode(song), '{title: Song}\n{comment}\n\n[C]Amazing [F]grace');
    });

    test('clamps externally supplied chord offsets while preserving order', () {
      final song = Song(
        lines: [
          LyricLine(
            text: 'abc',
            chords: [
              ChordAnchor(chord: Chord(root: Note.c), offset: -4),
              ChordAnchor(chord: Chord(root: Note.g), offset: 99),
              ChordAnchor(chord: Chord(root: Note.f), offset: 1),
            ],
          ),
        ],
      );

      expect(songCodec.encode(song), '[C]abc[G][F]');
    });
  });
}
