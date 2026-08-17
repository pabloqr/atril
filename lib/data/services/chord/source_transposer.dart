import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/core/utils/patterns.dart';
import 'package:atril/data/services/chord/chord_codec.dart';
import 'package:atril/data/services/chord/chromatic_transposition.dart';
import 'package:atril/data/services/chord/song_transposer.dart';
import 'package:atril/domain/models/chord/key_mode.dart';
import 'package:atril/domain/models/chord/key_signature.dart';
import 'package:atril/domain/models/chord/resolved_transposition.dart';
import 'package:atril/domain/models/song/directive_type.dart';

/// Applies chord transposition directly to ChordPro source text.
///
/// Source formatting and line endings are retained, making this service
/// suitable for editor operations where re-encoding the complete parsed song
/// would otherwise normalize the document.
final class const SourceTransposer() {
  final _songTransposer = const SongTransposer();

  /// Transposes every valid inline chord and supported key directive in
  /// [source] according to [transposition].
  ///
  /// Directive lines other than a resolvable key directive, invalid chord
  /// markers, lyric text, and line endings are preserved. A
  /// [TranspositionException] from a valid chord is allowed to propagate so
  /// callers never receive a partially transposed source.
  String transposeSource(String source, ChromaticTransposition transposition) {
    final resolvedTransposition = _songTransposer.resolve(transposition, sourceKey: _findSourceKey(source));

    final buffer = StringBuffer();
    var lineStart = 0;

    for (final lineEnding in Patterns.lineEndings.allMatches(source)) {
      buffer
        ..write(_transposeLine(source.substring(lineStart, lineEnding.start), resolvedTransposition))
        ..write(lineEnding.group(0));
      lineStart = lineEnding.end;
    }

    buffer.write(_transposeLine(source.substring(lineStart), resolvedTransposition));

    return buffer.toString();
  }

  /// Transposes the complete chord symbol in [chordSource].
  ///
  /// [sourceKey] is used, when available, to select consistent enharmonic
  /// spelling. Invalid chord symbols throw [FormatException]; unsupported
  /// spellings may throw [TranspositionException].
  String transposeChord(String chordSource, ChromaticTransposition transposition, {KeySignature? sourceKey}) {
    final resolvedTransposition = _songTransposer.resolve(transposition, sourceKey: sourceKey);

    return transposeChordResolved(chordSource, resolvedTransposition);
  }

  /// Transposes a parsed-and-resolved chord symbol without resolving the
  /// request again.
  ///
  /// This is useful while processing several source chords that share the same
  /// [transposition]. Invalid chord symbols throw [FormatException].
  String transposeChordResolved(String chordSource, ResolvedTransposition transposition) {
    final chord = chordCodec.decode(chordSource);

    return chordCodec.encode(_songTransposer.transposeChordResolved(chord, transposition));
  }

  /// Transposes one source line while preserving content outside chord tokens.
  ///
  /// A valid key directive receives [transposition]'s target key when one is
  /// available. Other directive-like lines are retained unchanged, and invalid
  /// inline chord tokens are left in place.
  String _transposeLine(String line, ResolvedTransposition transposition) {
    // SongCodec treats a line beginning with "{" as a directive or malformed
    // directive rather than parsing inline chords from it.
    if (line.trimLeft().startsWith('{')) {
      final directive = Patterns.directiveStrict.firstMatch(line);
      if (directive == null || directive.namedGroup('key')!.trim() != DirectiveType.key.name) return line;

      final currentValue = directive.namedGroup('value');
      if (currentValue == null) return line;

      final directiveString = directive.group(0)!;
      final key = directive.namedGroup('key')!;

      final keyEnd = directiveString.indexOf(key) + key.length;
      final valueStart = directiveString.indexOf(currentValue, keyEnd);

      final start = directive.start + valueStart;
      final end = start + currentValue.length;

      final newValue = transposition.targetKey?.toString();
      if (newValue == null) return line;

      return line.substring(0, start) + newValue + line.substring(end);
    }

    return line.replaceAllMapped(Patterns.chordInline, (match) {
      final chordSource = match.group(1)!;

      try {
        return '[${transposeChordResolved(chordSource, transposition)}]';
      } on FormatException {
        return match.group(0)!;
      }
    });
  }

  /// Returns the first supported key declared in [source], if any.
  ///
  /// Only major and minor key directives without a slash bass are recognized;
  /// malformed or unsupported directives are ignored.
  KeySignature? _findSourceKey(String source) {
    for (final line in source.split(Patterns.lineEndings)) {
      final directive = Patterns.directiveStrict.firstMatch(line);

      if (directive == null || directive.namedGroup('key')!.trim() != DirectiveType.key.name) {
        continue;
      }

      final value = directive.namedGroup('value')?.trim();
      if (value == null) continue;

      try {
        final chord = chordCodec.decode(value);

        final mode = switch (chord.extension) {
          null || '' => KeyMode.major,
          'm' => KeyMode.minor,
          _ => null,
        };

        if (mode == null || chord.bass != null) continue;

        return KeySignature.lookup[(chord.root, mode)];
      } on FormatException {
        continue;
      }
    }

    return null;
  }
}
