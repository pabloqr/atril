import 'package:atril/core/utils/command.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final class LoadingViewModel extends ChangeNotifier {
  final _log = Logger('LoadingViewModel');

  LoadingViewModel({required this._songRepository, required this.filename}) {
    load = Command0(_load)..execute();
  }

  final SongRepository _songRepository;
  final String filename;

  late final Command0<void> load;

  bool _isLoading = true;
  bool _exists = false;
  bool _hasError = false;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  bool get exists => _exists;

  @override
  void dispose() {
    load.dispose();

    super.dispose();
  }

  Future<Result> _load() async {
    _log.info('Checking if song \'$filename\' exists');

    final result = await _songRepository.existsSong(filename);

    switch (result) {
      case Ok<bool>(value: final value):
        _log.fine('Success checking if song \'$filename\' exists');

        _exists = value;
        _hasError = false;

        _log.info('Song \'$filename\' does ${_exists ? '' : 'not'} exist');

      case Error<bool>():
        _log.severe('Error while checking if song \'$filename\' exists', result.error);

        _exists = false;
        _hasError = true;
    }

    _isLoading = false;
    notifyListeners();

    return Result.ok(result);
  }
}
