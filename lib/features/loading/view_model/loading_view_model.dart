import 'package:atril/core/utils/command.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final class LoadingViewModel({required final SongRepository _songRepository, required final String filename})
    extends ChangeNotifier {
  final _log = Logger('LoadingViewModel');

  this {
    load = Command0(_load)..execute();
  }

  late final Command0<void> load;

  bool _exists = false;

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

        _log.info('Song \'$filename\' does ${_exists ? '' : 'not'} exist');

      case Error<bool>():
        _log.severe('Error while checking if song \'$filename\' exists', result.error);

        _exists = false;
    }

    notifyListeners();

    return Result.ok(result);
  }
}
