import 'package:atril/data/services/song/source_editor.dart';
import 'package:atril/domain/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final editor = SourceEditor();

  group('SourceEditor.insertDirective', () {
    test('inserts missing header directives in canonical order', () {
      final fragment = SourceFragment(source: '{title: Song}\n{capo: 2}\nVerse', selection: const NoSelection());

      final result = editor.insertDirective(fragment, DirectiveType.artist);

      expect(result.source, '{title: Song}\n{artist: }\n{capo: 2}\nVerse');
      expect(result.selection, isA<PositionSelection>().having((selection) => selection.position, 'position', 23));
    });

    test('selects an existing header directive value instead of duplicating it', () {
      final fragment = SourceFragment(source: '{title: Song}\nVerse', selection: const NoSelection());

      final result = editor.insertDirective(fragment, DirectiveType.title);

      expect(result.source, fragment.source);
      expect(result.selection, isA<RangeSelection>().having((selection) => selection.start, 'start', 8));
      expect((result.selection as RangeSelection).end, 12);
    });

    test('preserves source line ending convention when inserting body directives', () {
      final fragment = SourceFragment(source: '{title: Song}\r\nVerse', selection: const PositionSelection(15));

      final result = editor.insertDirective(fragment, DirectiveType.comment);

      expect(result.source, '{title: Song}\r\n{comment: }\r\nVerse');
      expect(result.selection, isA<PositionSelection>().having((selection) => selection.position, 'position', 25));
    });

    test('leaves body directives unchanged without a selection', () {
      final fragment = SourceFragment(source: 'Verse', selection: const NoSelection());

      expect(editor.insertDirective(fragment, DirectiveType.comment), same(fragment));
    });
  });

  group('SourceEditor.insertChord', () {
    test('inserts an empty chord marker at a caret position', () {
      final fragment = SourceFragment(source: 'Amazing grace', selection: const PositionSelection(8));

      final result = editor.insertChord(fragment);

      expect(result.source, 'Amazing []grace');
      expect(result.selection, isA<PositionSelection>().having((selection) => selection.position, 'position', 9));
    });

    test('wraps a selected valid chord and selects the chord text', () {
      final fragment = SourceFragment(source: 'C#m7', selection: RangeSelection(0, 4));

      final result = editor.insertChord(fragment);

      expect(result.source, '[C#m7]');
      expect(result.selection, isA<RangeSelection>().having((selection) => selection.start, 'start', 1));
      expect((result.selection as RangeSelection).end, 5);
    });

    test('replaces non-chord selected text with an empty chord marker', () {
      final fragment = SourceFragment(source: 'hello world', selection: RangeSelection(0, 11));

      final result = editor.insertChord(fragment);

      expect(result.source, '[]');
      expect(result.selection, isA<PositionSelection>().having((selection) => selection.position, 'position', 1));
    });

    test('selects chord text when caret is inside an existing marker', () {
      final fragment = SourceFragment(source: 'Play [C#m7] now', selection: const PositionSelection(8));

      final result = editor.insertChord(fragment);

      expect(result.source, fragment.source);
      expect(result.selection, isA<RangeSelection>().having((selection) => selection.start, 'start', 6));
      expect((result.selection as RangeSelection).end, 10);
    });

    test('does not insert chords in directive lines or across multiple lines', () {
      final directive = SourceFragment(source: '{title: Song}', selection: const PositionSelection(8));
      final multiline = SourceFragment(source: 'Line one\nLine two', selection: RangeSelection(0, 10));

      expect(editor.insertChord(directive), same(directive));
      expect(editor.insertChord(multiline), same(multiline));
    });
  });
}
