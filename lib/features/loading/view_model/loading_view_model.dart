import 'package:atril/core/utils/command.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:flutter/foundation.dart';

final class LoadingViewModel extends ChangeNotifier {
  LoadingViewModel({required this._songRepository, required this.filename}) {
    load = Command0(_load)..execute();
  }

  final SongRepository _songRepository;
  final String filename;

  late final Command0<void> load;

  bool isLoading = true;
  bool exists = false;
  bool hasError = false;

  @override
  void dispose() {
    load.dispose();

    super.dispose();
  }

  Future<Result> _load() async {
    final result = await _songRepository.existsSong(filename);

    switch (result) {
      case Ok<bool>(value: final value):
        exists = value;
        hasError = false;
      case Error<bool>():
        exists = false;
        hasError = true;
    }

    isLoading = false;
    notifyListeners();

    return Result.ok(result);
  }
}
