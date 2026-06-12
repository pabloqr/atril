import 'dart:convert';

import 'package:atril/core/utils/patterns.dart';
import 'package:atril/data/services/chord/chord_codec.dart';
import 'package:atril/domain/models/song.dart';

/// A [SongCodec] instance for encoding and decoding ChordPro documents.
///
/// Encoding converts a [Song] to canonical ChordPro source text. Decoding
/// parses source text into a [Song] containing ordered [Line]s and recoverable
/// [ParseIssue] diagnostics.
///
/// Example:
/// ```dart
/// final song = songCodec.decode(source);
/// final text = songCodec.encode(song);
/// ```
const SongCodec songCodec = SongCodec();

/// A [Codec] for encoding and decoding the document-oriented subset of
/// ChordPro used by Atril.
final class SongCodec extends Codec<Song, String> {
  const SongCodec();

  @override
  Converter<String, Song> get decoder => const _SongDecoder();

  @override
  Converter<Song, String> get encoder => const _SongEncoder();
}

/// Decodes ChordPro source text into a [Song].
final class _SongDecoder extends Converter<String, Song> {
  const _SongDecoder();

  /// Converts [input] into source-ordered song lines and diagnostics.
  ///
  /// Line endings are normalized in the model. Malformed directives and inline
  /// chords are retained as lyric text where possible and reported through
  /// [Song.issues], so recoverable user input does not abort the whole parse.
  @override
  Song convert(String input) {
    // Normalize line endings in the parsed model while retaining empty lines;
    // saving edited documents uses source text rather than this parsed model.
    final normalized = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final sourceLines = normalized.split('\n');

    final lines = <Line>[];
    final issues = <ParseIssue>[];

    var sourceOffset = 0;

    for (var index = 0; index < sourceLines.length; index++) {
      final sourceLine = sourceLines[index];

      lines.add(_convertLine(sourceLine, index + 1, sourceOffset, issues));

      sourceOffset += sourceLine.length + 1;
    }

    return Song(lines: lines, issues: issues);
  }

  static Line _convertLine(String sourceLine, int lineIndex, int sourceOffset, List<ParseIssue> issues) {
    if (sourceLine.trim().isEmpty) return EmptyLine();

    final directiveLine = _tryConvertDirectiveLine(sourceLine, lineIndex, sourceOffset, issues);

    return directiveLine ?? _convertLyricLine(sourceLine, lineIndex, sourceOffset, issues);
  }

  static Line? _tryConvertDirectiveLine(String sourceLine, int lineIndex, int sourceOffset, List<ParseIssue> issues) {
    final openingIndex = sourceLine.indexOf('{');
    final closingIndex = sourceLine.indexOf('}');

    if (sourceLine.trim().startsWith('{')) {
      final directive = Patterns.directiveStrict.firstMatch(sourceLine);
      if (directive != null) {
        return DirectiveLine(
          directive: Directive(name: directive.namedGroup('key')!.trim(), value: directive.namedGroup('value')),
        );
      }

      issues.add(
        _malformedDirectiveIssue(
          message: 'Malformed directive.',
          sourceOffset: sourceOffset + openingIndex,
          lineIndex: lineIndex,
          position: openingIndex + 1,
          length: sourceLine.length - openingIndex,
        ),
      );

      return LyricLine(text: sourceLine);
    }

    if (openingIndex != -1) {
      issues.add(
        _malformedDirectiveIssue(
          message: 'Unexpected directive opening curly bracket.',
          sourceOffset: sourceOffset + openingIndex,
          lineIndex: lineIndex,
          position: openingIndex + 1,
          length: sourceLine.length - openingIndex,
        ),
      );

      return null;
    }

    if (closingIndex != -1) {
      issues.add(
        _malformedDirectiveIssue(
          message: 'Unexpected directive closing curly bracket.',
          sourceOffset: sourceOffset + closingIndex,
          lineIndex: lineIndex,
          position: closingIndex + 1,
          length: 1,
        ),
      );

      return null;
    }

    return null;
  }

  static LyricLine _convertLyricLine(String sourceLine, int lineIndex, int sourceOffset, List<ParseIssue> issues) {
    final text = StringBuffer();
    final chords = <ChordAnchor>[];
    var position = 0;

    while (position < sourceLine.length) {
      final character = sourceLine[position];
      if (character == ']') {
        issues.add(
          ParseIssue(
            code: .malformedChord,
            severity: .error,
            message: 'Unexpected inline chord closing bracket.',
            location: SourceLocation(
              sourceOffset: sourceOffset + position,
              lineIndex: lineIndex,
              position: position + 1,
              length: 1,
            ),
          ),
        );

        text.write(character);
        position++;
        continue;
      }

      if (character != '[') {
        text.write(character);
        position++;
        continue;
      }

      final closingIndex = sourceLine.indexOf(']', position + 1);
      if (closingIndex == -1) {
        issues.add(
          ParseIssue(
            code: .malformedChord,
            severity: .error,
            message: 'Unclosed inline chord.',
            location: SourceLocation(
              sourceOffset: sourceOffset + position,
              lineIndex: lineIndex,
              position: position + 1,
              length: sourceLine.length - position,
            ),
          ),
        );

        text.write(sourceLine.substring(position));
        break;
      }

      final chord = sourceLine.substring(position + 1, closingIndex);
      if (chord.isEmpty) {
        issues.add(
          ParseIssue(
            code: .invalidChord,
            severity: .error,
            message: 'Empty inline chord marker.',
            location: SourceLocation(
              sourceOffset: sourceOffset + position,
              lineIndex: lineIndex,
              position: position + 1,
              length: closingIndex - position + 1,
            ),
          ),
        );

        text.write(sourceLine.substring(position, closingIndex + 1));
        position = closingIndex + 1;
        continue;
      }

      try {
        // The marker is removed from lyrics, so the accumulated lyric length is
        // the stable position used later for serialization and rendering.
        chords.add(ChordAnchor(chord: chordCodec.decode(chord), offset: text.length));
      } on FormatException catch (e) {
        issues.add(
          ParseIssue(
            code: .invalidChord,
            severity: .error,
            message: e.message,
            location: SourceLocation(
              sourceOffset: sourceOffset + position,
              lineIndex: lineIndex,
              position: position + 1,
              length: closingIndex - position + 1,
            ),
          ),
        );

        text.write(sourceLine.substring(position, closingIndex + 1));
      }

      position = closingIndex + 1;
    }

    return LyricLine(text: text.toString(), chords: chords);
  }

  static ParseIssue _malformedDirectiveIssue({
    required String message,
    required int sourceOffset,
    required int lineIndex,
    required int position,
    required int length,
  }) {
    return ParseIssue(
      code: .malformedDirective,
      severity: .error,
      message: message,
      location: SourceLocation(sourceOffset: sourceOffset, lineIndex: lineIndex, position: position, length: length),
    );
  }
}

/// Encodes a [Song] to canonical ChordPro source text.
final class _SongEncoder extends Converter<Song, String> {
  const _SongEncoder();

  /// Converts [input] to normalized source using LF line separators.
  ///
  /// Parser issues are not serialized because they describe the source rather
  /// than song content.
  @override
  String convert(Song input) => input.lines.map(_convertLine).join('\n');

  static String _convertLine(Line line) {
    return switch (line) {
      DirectiveLine(:final name, :final value) => value == null ? '{$name}' : '{$name: $value}',
      LyricLine(:final text, :final chords) => _convertLyricLine(text, chords),
      EmptyLine() => '',
    };
  }

  static String _convertLyricLine(String text, List<ChordAnchor> chords) {
    final buffer = StringBuffer();
    var position = 0;

    for (final chord in chords) {
      // Defensive clamping keeps malformed externally constructed models
      // serializable and preserves the ordering already supplied by callers.
      final offset = chord.offset.clamp(position, text.length).toInt();
      buffer
        ..write(text.substring(position, offset))
        ..write('[${chord.chord}]');
      position = offset;
    }

    buffer.write(text.substring(position));
    return buffer.toString();
  }
}
