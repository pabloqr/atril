import 'package:atril/data/services/song/source_editor.dart';
import 'package:atril/domain/models/song.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:flutter/foundation.dart';

final class EditorViewModel extends ChangeNotifier {
  EditorViewModel({required this._workspaceViewModel, required this._sourceEditor})
    : _knownSource = _workspaceViewModel.source {
    _workspaceViewModel.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceViewModel _workspaceViewModel;
  final SourceEditor _sourceEditor;

  bool _updatingWorkspace = false;
  String _knownSource;

  Selection _selection = NoSelection();

  String get source => _workspaceViewModel.source;

  Selection get selection => _selection;

  @override
  void dispose() {
    _workspaceViewModel.removeListener(_handleWorkspaceChanged);

    super.dispose();
  }

  void update(String source, Selection selection) {
    _apply(source, selection, false);
  }

  void insertDirective(DirectiveType directiveType) {
    final result = _sourceEditor.insertDirective(SourceFragment(source: source, selection: _selection), directiveType);
    _apply(result.source, result.selection);
  }

  void insertChord() {
    final result = _sourceEditor.insertChord(SourceFragment(source: source, selection: _selection));
    _apply(result.source, result.selection);
  }

  void _apply(String source, Selection selection, [bool notify = true]) {
    _knownSource = source;
    _selection = selection;

    _updatingWorkspace = true;
    try {
      _workspaceViewModel.source = source;
    } finally {
      _updatingWorkspace = false;
    }

    if (notify) notifyListeners();
  }

  void _handleWorkspaceChanged() {
    if (_updatingWorkspace) return;

    final source = _workspaceViewModel.source;

    if (source != _knownSource) {
      _knownSource = source;
      _selection = const NoSelection();
    }

    notifyListeners();
  }
}
