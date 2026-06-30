import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Song.copyWith', () {
    test('rebuilds metadata from replacement lines', () {
      final song = Song(
        lines: [
          DirectiveLine(
            directive: Directive(name: 'title', value: 'Old'),
          ),
        ],
      );

      final updated = song.copyWith(
        lines: [
          DirectiveLine(
            directive: Directive(name: 'title', value: 'New'),
          ),
        ],
      );

      expect(updated.metadata.title, 'New');
      expect(song.metadata.title, 'Old');
    });
  });

  group('Song metadata editors', () {
    test('insert header directives in canonical order', () {
      final song = Song(
        lines: [LyricLine(text: 'First line')],
      ).withCapo(2).withArtist('Artist').withKey(Chord(root: Note.c)).withTitle('Title');

      expect(song.lines.whereType<DirectiveLine>().map((line) => line.name), ['title', 'artist', 'key', 'capo']);
      expect(song.metadata.title, 'Title');
      expect(song.metadata.artist, 'Artist');
      expect(song.metadata.key.toString(), 'C');
      expect(song.metadata.capo, 2);
    });

    test('updates existing directive and removes duplicates', () {
      final song = Song(
        lines: [
          DirectiveLine(
            directive: Directive(name: 'title', value: 'Old'),
          ),
          DirectiveLine(
            directive: Directive(name: 'title', value: 'Duplicate'),
          ),
          LyricLine(text: 'First line'),
        ],
      );

      final updated = song.withTitle('New');

      expect(updated.metadata.title, 'New');
      expect(updated.lines.whereType<DirectiveLine>().where((line) => line.name == 'title'), hasLength(1));
    });

    test('removes directive when value is null or blank', () {
      final song = Song(
        lines: [
          DirectiveLine(
            directive: Directive(name: 'title', value: 'Title'),
          ),
          DirectiveLine(
            directive: Directive(name: 'artist', value: 'Artist'),
          ),
          LyricLine(text: 'First line'),
        ],
      );

      final withoutTitle = song.withTitle(null);
      final withoutArtist = song.withArtist(' ');

      expect(withoutTitle.metadata.title, isNull);
      expect(withoutTitle.metadata.artist, 'Artist');
      expect(withoutArtist.metadata.artist, isNull);
      expect(withoutArtist.metadata.title, 'Title');
    });
  });
}
