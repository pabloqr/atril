import 'package:atril/core/utils/command.dart';
import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:atril/data/services/song/song_codec.dart';
import 'package:atril/domain/models/persistence/song_file.dart';
import 'package:atril/domain/models/song/song.dart';
import 'package:flutter/foundation.dart';

final class WorkspaceViewModel extends ChangeNotifier {
  WorkspaceViewModel({required this._songRepository, required this._filename}) : _source = '' {
    load = Command0(_load)..execute();

    saveSong = Command0(_saveSong);
    renameSongFilename = Command1(_renameSong);
    deleteSong = Command0(_deleteSong);
  }

  final SongRepository _songRepository;

  late final Command0<void> load;
  late final Command0<void> saveSong;
  late final Command1<void, String> renameSongFilename;
  late final Command0<void> deleteSong;

  String _filename;
  String _source;

  String? _cachedSource;
  Song? _cachedSong;

  String get filename => _filename;

  String get source => _source;

  Song get song {
    if (_cachedSource != _source) {
      _cachedSource = _source;
      _cachedSong = songCodec.decode(_source);
    }

    return _cachedSong!;
  }

  set filename(String filename) {
    if (filename == _filename) return;

    _filename = filename;
    notifyListeners();
  }

  set source(String source) {
    if (source == _source) return;

    _source = source;
    notifyListeners();
  }

  Future<Result> _load() async {
    final songResult = await _songRepository.getSong(_filename);
    switch (songResult) {
      case Ok<SongFile?>():
        if (songResult.value == null) {
          return Result.error(AtrilException('Song \'$_filename\' no longer exists.'));
        }

        _source = songResult.value!.source;
        notifyListeners();
      case Error<SongFile?>():
    }

    return songResult;
  }

  Future<Result> _saveSong() async {
    if (song.issues.isNotEmpty) return Result.error(AtrilException('Song has pending issues.'));

    final createResult = await _songRepository.saveSong(SongFile(filename: _filename, source: _source));
    switch (createResult) {
      case Ok<SongFile>():
        notifyListeners();
      case Error<SongFile>():
    }

    return createResult;
  }

  Future<Result> _renameSong(String filename) async {
    final deleteResult = await _songRepository.deleteSong(filename);
    switch (deleteResult) {
      case Ok<void>():
        final createResult = await _songRepository.saveSong(SongFile(filename: filename, source: _source));
        switch (createResult) {
          case Ok<SongFile>():
            this.filename = filename;
            notifyListeners();

            return createResult;
          case Error<SongFile>():
        }
      case Error<void>():
    }

    return deleteResult;
  }

  Future<Result> _deleteSong() async {
    final deleteResult = await _songRepository.deleteSong(_filename);
    switch (deleteResult) {
      case Ok<void>():
        notifyListeners();
      case Error<void>():
    }

    return deleteResult;
  }
}
