import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:flutter/foundation.dart';

final class EditorViewModel extends ChangeNotifier {
  EditorViewModel({required this._workspaceViewModel}) {
    _workspaceViewModel.addListener(notifyListeners);
  }

  final WorkspaceViewModel _workspaceViewModel;

  int start = 0;
  int end = 0;

  String get source => _workspaceViewModel.source;

  set source(String source) => _workspaceViewModel.source = source;

  @override
  void dispose() {
    _workspaceViewModel.removeListener(notifyListeners);

    super.dispose();
  }
}
