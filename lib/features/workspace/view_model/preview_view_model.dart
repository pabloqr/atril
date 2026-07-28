import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/domain/models/song/song.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:flutter/foundation.dart';

class PreviewViewModel extends ChangeNotifier {
  PreviewViewModel({required this._workspace}) {
    _workspace.addListener(notifyListeners);
  }

  final WorkspaceViewModel _workspace;

  Song get song => _workspace.song.issues.isEmpty ? _workspace.song : throw AtrilException('Song has pending issues.');

  @override
  void dispose() {
    _workspace.removeListener(notifyListeners);
    
    super.dispose();
  }
}
