import 'dart:math';

import 'package:atril/core/extensions/regexp.dart';
import 'package:atril/core/extensions/string.dart';
import 'package:atril/core/utils/patterns.dart';
import 'package:atril/domain/models/song.dart';

/// A selection state returned with source-editing operations.
sealed class Selection {
  /// Creates a selection variant.
  const Selection();
}

/// Indicates that no editor selection or caret position is available.
final class NoSelection extends Selection {
  /// Creates an absent selection.
  const NoSelection();
}

/// A collapsed selection representing a caret at [position].
final class PositionSelection extends Selection {
  /// Creates a caret position using a zero-based source offset.
  const PositionSelection(this.position);

  /// The zero-based caret offset.
  final int position;
}

/// A normalized, half-open source selection from [start] to [end].
final class RangeSelection extends Selection {
  /// Creates a selection and orders the supplied endpoints.
  RangeSelection(int start, int end) : start = min(start, end), end = max(start, end);

  /// The inclusive zero-based start offset.
  final int start;

  /// The exclusive zero-based end offset.
  final int end;
}

/// Source text paired with the selection an editor should apply next.
final class SourceFragment {
  /// Creates a source fragment with its resulting [selection].
  const SourceFragment({required this.source, required this.selection});

  /// The complete source document after an editing operation.
  final String source;

  /// The caret or range to expose after replacing the editor contents.
  final Selection selection;
}

sealed class SourceEditResult {
  const SourceEditResult();
}

final class SourceEditApplied extends SourceEditResult {
  const SourceEditApplied(this.fragment);

  final SourceFragment fragment;
}

final class SourceEditRejected extends SourceEditResult {
  const SourceEditRejected(this.reason);

  final SourceEditRejection reason;
}

enum SourceEditRejection { noSelection, invalidSelection, multilineSelection, directiveLine, unsupportedDirective }

/// Performs source-preserving insertions for Atril's ChordPro editor.
///
/// Operations modify only the requested range and retain the source's existing
/// line-ending convention. Header directives are kept in canonical order;
/// body directives and chords are inserted relative to the current selection.
final class SourceEditor {
  const SourceEditor();

  /// Inserts or selects a directive according to its structural location.
  ///
  /// Existing header directives are not duplicated: their value is selected
  /// instead. A missing header directive is inserted among other recognized
  /// header fields. Body directives require a selection and are inserted at
  /// the start of its line. Unsupported locations leave [fragment] unchanged.
  SourceEditResult insertDirective(SourceFragment fragment, DirectiveType directiveType) {
    final lines = _sourceLines(fragment.source);

    if (directiveType.location == DirectiveLocation.header) {
      return SourceEditApplied(_insertHeaderDirective(fragment.source, lines, directiveType));
    }

    final insertPosition = switch (fragment.selection) {
      NoSelection() => null,
      PositionSelection(:final position) => position,
      RangeSelection(:final start) => start,
    };

    if (_isValidOffset(insertPosition, fragment.source.length)) {
      final line = lines[lines.indexWhere((line) => line.contentEnd >= insertPosition!)];
      final fragmentOffset = line.start;

      return SourceEditApplied(
        _insertLineBefore(fragment.source, fragmentOffset, _templateForDirective(directiveType.name)),
      );
    }

    return SourceEditRejected(SourceEditRejection.invalidSelection);
  }

  /// Inserts an inline chord marker or selects an existing marker's contents.
  ///
  /// The operation is limited to one non-directive line. A caret inside an
  /// existing marker selects its chord text. A selected valid chord is wrapped
  /// in brackets; other selected text is replaced with an empty marker.
  /// Invalid, cross-line, or absent selections leave [fragment] unchanged.
  SourceEditResult insertChord(SourceFragment fragment) {
    final lines = _sourceLines(fragment.source);

    final (insertPosition, endPosition) = switch (fragment.selection) {
      NoSelection() => (null, null),
      PositionSelection(:final position) => (position, position),
      RangeSelection(:final start, :final end) => (start, end),
    };

    final validInsertPosition = _isValidOffset(insertPosition, fragment.source.length);
    final validEndPosition = _isValidOffset(endPosition, fragment.source.length);

    if (!validInsertPosition || !validEndPosition) return SourceEditRejected(SourceEditRejection.invalidSelection);

    final line = lines[lines.indexWhere((line) => line.contentEnd >= insertPosition!)];
    final endLine = lines[lines.indexWhere((line) => line.contentEnd >= endPosition!)];

    if (line.start != endLine.start) return SourceEditRejected(SourceEditRejection.multilineSelection);

    final directive = _parseDirective(line);
    if (directive != null) return SourceEditRejected(SourceEditRejection.directiveLine);

    final chords = Patterns.chordInline.allMatches(line.content);
    for (final chord in chords) {
      final chordStart = line.start + chord.start;
      final chordEnd = line.start + chord.end;

      if (chordStart < insertPosition! && endPosition! < chordEnd) {
        final chordRange = chord.namedGroupRange('chord')!;
        return SourceEditApplied(
          SourceFragment(
            source: fragment.source,
            selection: RangeSelection(line.start + chordRange.$1, line.start + chordRange.$2),
          ),
        );
      }
    }

    if (insertPosition == endPosition) {
      return SourceEditApplied(_insertBefore(fragment.source, insertPosition!, _templateForChord()));
    }

    final chord = Patterns.chord.firstMatch(
      line.content.substring(insertPosition! - line.start, endPosition! - line.start),
    );

    if (chord != null) {
      return SourceEditApplied(
        SourceFragment(
          source: fragment.source.replaceRange(
            insertPosition,
            endPosition,
            _templateForChord(fragment.source.substring(insertPosition, endPosition)),
          ),
          selection: RangeSelection(insertPosition + 1, endPosition + 1),
        ),
      );
    }

    return SourceEditApplied(
      SourceFragment(
        source: fragment.source.replaceRange(insertPosition, endPosition, _templateForChord()),
        selection: PositionSelection(insertPosition + 1),
      ),
    );
  }

  SourceFragment _insertHeaderDirective(String source, List<_SourceLine> lines, DirectiveType directiveType) {
    final directive = _findDirective(lines, directiveType);
    if (directive != null) {
      final selection = directive.valueStart == directive.valueEnd
          ? PositionSelection(directive.valueStart)
          : RangeSelection(directive.valueStart, directive.valueEnd);

      return SourceFragment(source: source, selection: selection);
    }

    final template = _templateForDirective(directiveType.name);

    // Compare only recognized header directives. Unknown and body directives
    // stay untouched because this editor promises source-preserving changes.
    final headerLines = _headerLines(lines);
    for (final line in headerLines) {
      final existingDirective = _parseDirective(line)!;
      if (existingDirective.type.order > directiveType.order) {
        return _insertLineBefore(source, line.start, template);
      }
    }

    if (headerLines.isEmpty) {
      return _insertLineBefore(source, 0, template);
    }

    if (headerLines.last.end < source.length) {
      return _insertLineBefore(source, headerLines.last.end, template);
    }

    final separator = _endsWithNewline(source) ? '' : _newlineFor(source);
    final fragmentOffset = headerLines.last.end + _fragmentOffset(template);
    return SourceFragment(source: '$source$separator$template', selection: PositionSelection(fragmentOffset));
  }

  List<_SourceLine> _sourceLines(String source) {
    final lines = <_SourceLine>[];

    var index = 0;
    for (final line in Patterns.lineEndings.allMatches(source)) {
      lines.add(_SourceLine(start: index, content: source.substring(index, line.start), lineEnding: line.group(0)!));

      index = line.end;
    }

    if (index < source.length) {
      lines.add(_SourceLine(start: index, content: source.substring(index), lineEnding: ''));
    } else {
      lines.add(_SourceLine(start: source.length, content: '', lineEnding: ''));
    }

    return lines;
  }

  List<_SourceLine> _headerLines(List<_SourceLine> lines) {
    return lines.where((line) {
      final directive = _parseDirective(line);
      return directive != null && directive.type.location == DirectiveLocation.header;
    }).toList();
  }

  _DirectiveMatch? _findDirective(List<_SourceLine> lines, DirectiveType directiveType) {
    for (final line in lines) {
      final directive = _parseDirective(line);
      if (directive != null && directive.type == directiveType) {
        return directive;
      }
    }

    return null;
  }

  _DirectiveMatch? _parseDirective(_SourceLine line) {
    final directive = Patterns.directivePermissive.firstMatch(line.content);

    if (directive != null) {
      final key = directive.namedGroup('key')!.trim().toLowerCase();
      final valueRange = directive.namedGroupRange('value');

      if (valueRange != null) {
        return _DirectiveMatch(
          type: DirectiveType.lookup[key] ?? DirectiveType.unknown,
          valueStart: line.start + valueRange.$1,
          valueEnd: line.start + valueRange.$2,
        );
      }

      final keyRange = directive.namedGroupRange('key')!;
      final colonIndex = line.content.indexOf(':');

      final position = line.start + (colonIndex != -1 ? colonIndex : keyRange.$2) + 1;

      return _DirectiveMatch(
        type: DirectiveType.lookup[key] ?? DirectiveType.unknown,
        valueStart: position,
        valueEnd: position,
      );
    }

    return null;
  }

  SourceFragment _insertBefore(String source, int offset, String template) {
    return SourceFragment(
      source: source.replaceRange(offset, offset, template),
      selection: PositionSelection(offset + template.indexOfAny(['}', ']'])),
    );
  }

  SourceFragment _insertLineBefore(String source, int offset, String template) {
    if (source.isEmpty) {
      final fragmentOffset = _fragmentOffset(template);

      return SourceFragment(source: template, selection: PositionSelection(fragmentOffset));
    }

    final insertion = '$template${_newlineFor(source)}';
    final fragmentOffset = offset + template.indexOfAny(['}', ']']);

    return SourceFragment(
      source: source.replaceRange(offset, offset, insertion),
      selection: PositionSelection(fragmentOffset),
    );
  }

  String _templateForDirective(String name) => '{$name: }';

  String _templateForChord([String chord = '']) => '[$chord]';

  bool _isValidOffset(int? offset, int sourceLength) => offset != null && 0 <= offset && offset <= sourceLength;

  int _fragmentOffset(String template) => template.indexOfAny(['}', ']']);

  String _newlineFor(String source) {
    final match = Patterns.lineEndings.firstMatch(source);
    return match?.group(0) ?? '\n';
  }

  bool _endsWithNewline(String source) => source.endsWith('\n') || source.endsWith('\r');
}

final class _SourceLine {
  const _SourceLine({required this.start, required this.content, required this.lineEnding});

  final int start;

  final String content;

  final String lineEnding;

  int get contentEnd => start + content.length;

  int get end => contentEnd + lineEnding.length;
}

final class _DirectiveMatch {
  const _DirectiveMatch({required this.type, required this.valueStart, required this.valueEnd});

  final DirectiveType type;

  final int valueStart;
  final int valueEnd;
}
