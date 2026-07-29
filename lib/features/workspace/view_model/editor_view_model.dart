import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/data/services/chord/source_transposer.dart';
import 'package:atril/data/services/song/source_editor.dart';
import 'package:atril/domain/models/chord.dart';
import 'package:atril/domain/models/song.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:flutter/foundation.dart';

final class EditorViewModel extends ChangeNotifier {
  EditorViewModel({required this._workspaceViewModel, required this._sourceEditor, required this._sourceTransposer})
    : _knownSource = _workspaceViewModel.source {
    _workspaceViewModel.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceViewModel _workspaceViewModel;

  final SourceEditor _sourceEditor;
  final SourceTransposer _sourceTransposer;

  bool _updatingWorkspace = false;
  String _knownSource;

  int? _activeIssueIndex;

  Selection _selection = NoSelection();

  String get source => _workspaceViewModel.source;

  ParseIssue? get activeIssue {
    final index = _activeIssueIndex;
    final issues = _workspaceViewModel.song.issues;

    if (index == null || index < 0 || index >= issues.length) return null;
    return issues[index];
  }

  int? get activeIssueNumber => _activeIssueIndex == null ? null : _activeIssueIndex! + 1;

  int get issuesCount => _workspaceViewModel.issuesCount;

  Selection get selection => _selection;

  @override
  void dispose() {
    _workspaceViewModel.removeListener(_handleWorkspaceChanged);

    super.dispose();
  }

  void _handleWorkspaceChanged() {
    if (_updatingWorkspace) return;

    final source = _workspaceViewModel.source;

    if (source != _knownSource) {
      _knownSource = source;
      _selection = const NoSelection();
      _activeIssueIndex = null;
    }

    notifyListeners();
  }

  void update(String source, Selection selection) {
    _activeIssueIndex = null;
    _apply(source, selection, false);
  }

  SourceEditResult insertDirective(DirectiveType directiveType) {
    final result = _sourceEditor.insertDirective(SourceFragment(source: source, selection: _selection), directiveType);

    if (result case SourceEditApplied(:final fragment)) {
      _apply(fragment.source, fragment.selection);
    }

    return result;
  }

  SourceEditResult insertChord() {
    final result = _sourceEditor.insertChord(SourceFragment(source: source, selection: _selection));

    if (result case SourceEditApplied(:final fragment)) {
      _apply(fragment.source, fragment.selection);
    }

    return result;
  }

  String? transpose(int semitones) {
    try {
      final interval = Interval.lookup[semitones.abs() % 12]!;
      final direction = semitones.isNegative ? TransposeDirection.down : TransposeDirection.up;

      final transposedSource = _sourceTransposer.transposeSource(source, interval, direction);

      if (transposedSource == source) return null;

      _apply(transposedSource, _selection);
      return null;
    } on TranspositionException catch (e) {
      return e.message;
    }
  }

  bool selectNextIssue() {
    final issues = _workspaceViewModel.song.issues;

    if (issues.isEmpty) {
      _activeIssueIndex = null;
      return false;
    }

    final activeIndex = _activeIssueIndex;

    final nextIndex = activeIndex != null && activeIndex >= 0 && activeIndex < issues.length
        ? (activeIndex + 1) % issues.length
        : _findNextIssueIndex(issues);

    _activeIssueIndex = nextIndex;

    final issue = issues[nextIndex];
    final location = issue.location;
    final sourceLength = source.length;

    final start = location.sourceOffset.clamp(0, sourceLength);
    final end = (location.sourceOffset + location.length).clamp(start, sourceLength);

    _selection = start == end ? PositionSelection(start) : RangeSelection(start, end);

    notifyListeners();
    return true;
  }

  void _apply(String source, Selection selection, [bool notify = true]) {
    _knownSource = source;
    _selection = selection;

    _activeIssueIndex = null;

    _updatingWorkspace = true;
    try {
      _workspaceViewModel.source = source;
    } finally {
      _updatingWorkspace = false;
    }

    if (notify) notifyListeners();
  }

  int _findNextIssueIndex(List<ParseIssue> issues) {
    if (_selection case NoSelection()) {
      return 0;
    }

    final int anchor;
    int? selectedStart;
    int? selectedEnd;

    switch (_selection) {
      case PositionSelection(:final position):
        anchor = position;

      case RangeSelection(:final start, :final end):
        selectedStart = start;
        selectedEnd = end;
        anchor = end;

      case NoSelection():
        return 0;
    }

    int? containingIndex;
    int? followingIndex;

    for (var index = 0; index < issues.length; index++) {
      final location = issues[index].location;
      final issueStart = location.sourceOffset;
      final issueEnd = issueStart + location.length;

      if (selectedStart == issueStart && selectedEnd == issueEnd) return (index + 1) % issues.length;

      if (containingIndex == null && issueStart <= anchor && anchor < issueEnd) containingIndex = index;
      if (followingIndex == null && issueStart >= anchor) followingIndex = index;

      if (issueStart > anchor) break;
    }

    return containingIndex ?? followingIndex ?? 0;
  }
}
