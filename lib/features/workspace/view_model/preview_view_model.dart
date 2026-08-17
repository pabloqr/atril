import 'package:atril/domain/models/song/song.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:flutter/foundation.dart';

class PreviewViewModel({required final WorkspaceViewModel _workspaceViewModel}) extends ChangeNotifier {
  this {
    _workspaceViewModel.addListener(_handleWorkspaceChanged);
  }

  Song get song => _workspaceViewModel.song;

  bool get hasIssues => song.issues.isNotEmpty;

  @override
  void dispose() {
    _workspaceViewModel.removeListener(_handleWorkspaceChanged);

    super.dispose();
  }

  void _handleWorkspaceChanged() {
    notifyListeners();
  }
}
