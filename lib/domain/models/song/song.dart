import 'package:atril/domain/models/chord/chord.dart';
import 'package:atril/domain/models/song/directive.dart';
import 'package:atril/domain/models/song/directive_type.dart';
import 'package:atril/domain/models/song/line.dart';
import 'package:atril/domain/models/song/metadata.dart';
import 'package:atril/domain/models/song/parse_issue.dart';

/// A complete song represented as ordered logical lines plus extracted metadata.
///
/// [Song] is the aggregate root for the song domain model. It preserves the
/// document body as an ordered list of [Line] objects and exposes a [Metadata]
/// object for information that has been extracted or assigned separately.
///
/// The constructor derives [metadata] from the directive lines currently present
/// in [lines]. This keeps the aggregate convenient for read-only use after
/// parsing, but it also means [metadata] is a snapshot: mutating nested objects
/// inside existing line instances, if they are mutable, will not rebuild the
/// metadata object.
final class Song {
  /// Creates a song from ordered logical [lines] and parser [issues].
  ///
  /// Directive lines are inspected to build [metadata]. The provided list is
  /// copied into an unmodifiable list, so later mutations to the argument do
  /// not change [lines]. The [Line] objects themselves are not deep-copied.
  Song({List<Line> lines = const [], List<ParseIssue> issues = const []})
    : metadata = Metadata(directives: lines.whereType<DirectiveLine>().toList()),
      lines = List.unmodifiable(lines),
      issues = List.unmodifiable(issues);

  /// Metadata associated with the song.
  ///
  /// This is extracted from [DirectiveLine] entries in [lines] during
  /// construction.
  final Metadata metadata;

  /// The song body as ordered logical lines.
  ///
  /// The list is unmodifiable and preserves the order supplied to the
  /// constructor.
  final List<Line> lines;

  /// Diagnostics associated with the source used to construct this song.
  ///
  /// The list is unmodifiable. Recoverable errors may coexist with parsed
  /// [lines], allowing consumers to show a partial preview.
  final List<ParseIssue> issues;

  /// Creates a new song by replacing the supplied aggregate fields.
  ///
  /// [metadata] is intentionally not copied directly because it is derived from
  /// directive lines during construction.
  Song copyWith({List<Line>? lines, List<ParseIssue>? issues}) {
    return Song(lines: lines ?? this.lines, issues: issues ?? this.issues);
  }

  /// Returns a copy with the title directive updated or removed.
  Song withTitle(String? title) => _withHeaderDirective(DirectiveType.title, title);

  /// Returns a copy with the artist directive updated or removed.
  Song withArtist(String? artist) => _withHeaderDirective(DirectiveType.artist, artist);

  /// Returns a copy with the key directive updated or removed.
  Song withKey(Chord? key) => _withHeaderDirective(DirectiveType.key, key);

  /// Returns a copy with the capo directive updated or removed.
  Song withCapo(int? capo) => _withHeaderDirective(DirectiveType.capo, capo);

  Song _withHeaderDirective(DirectiveType type, Object? value) {
    final normalizedValue = value?.toString().trim();
    final updatedLines = lines.where((line) => line is! DirectiveLine || line.name != type.name).toList();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return copyWith(lines: updatedLines);
    }

    updatedLines.insert(
      _headerInsertIndex(updatedLines, type),
      DirectiveLine(
        directive: Directive(name: type.name, value: normalizedValue),
      ),
    );

    return copyWith(lines: updatedLines);
  }

  int _headerInsertIndex(List<Line> lines, DirectiveType type) {
    var lastHeaderIndex = -1;

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line is! DirectiveLine) continue;

      final directiveType = DirectiveType.lookup[line.name];
      if (directiveType == null || directiveType.location != DirectiveLocation.header) continue;

      if (directiveType.order > type.order) return index;

      lastHeaderIndex = index;
    }

    return lastHeaderIndex + 1;
  }
}
