import 'dart:io';

import 'package:atril/core/config/constants.dart';
import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/services/persistence/persistence_service.dart';
import 'package:atril/domain/models/persistence/song_file.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

/// Repository for Atril's local ChordPro song library.
///
/// The repository works with source files rather than parsed song aggregates:
/// parsing, validation of ChordPro content, and metadata extraction belong to
/// the song codec and UI flow.
abstract final class SongRepository {
  Future<Result<bool>> existsSong(String filename);

  /// Reads every supported song file from the configured library directory.
  Future<Result<List<SongFile>>> getSongs();

  Future<Result<SongFile?>> getSong(String filename);

  /// Validates the storage name and writes the song using Atril's canonical
  /// extension.
  Future<Result<SongFile>> saveSong(SongFile song);

  /// Deletes the canonical file for [filename].
  Future<Result<void>> deleteSong(String filename);
}

/// File-backed [SongRepository] using a [PersistenceService].
final class SongRepositoryImpl implements SongRepository {
  final _log = Logger('SongRepository');

  SongRepositoryImpl({required this._service, this.songDirPath = Constants.songDirPath});

  static final RegExp _safeNamePattern = RegExp(r'^[A-Za-z0-9_-]+$');

  final PersistenceService _service;

  final String songDirPath;

  @override
  Future<Result<bool>> existsSong(String filename) async {
    try {
      _log.info('Checking if song \'$filename\' exists');

      if (!_isValidName(filename)) {
        return Result.error(ValidationException('Only letters, digits, underscores and hyphens are allowed.'));
      }

      final exists = await _service.existsFile(_songPath(_addExtension(filename)));
      return Result.ok(exists);
    } on Exception catch (e) {
      _log.severe('Error while checking if \'$filename\' exists', e);

      return Result.error(e);
    }
  }

  @override
  Future<Result<List<SongFile>>> getSongs() async {
    try {
      _log.info('Reading songs in directory \'$songDirPath\'');
      _log.info('Listing directory \'$songDirPath\'');

      final entities = await _service.listDirectory(songDirPath);

      _log.info('Found ${entities.length} entities');
      _log.info('Processing entries in directory \'$songDirPath\': filtering and sorting');

      final songEntities = entities.where((entity) {
        final extension = path.extension(entity.path).substring(1);
        return Constants.allowedFileExtensions.contains(extension);
      }).toList();
      songEntities.sort(((a, b) => a.path.compareTo(b.path)));

      _log.info('Reading entries content');

      final songFiles = await Future.wait(
        songEntities.map((entity) async {
          final file = await _service.readFile(_songPath(entity.uri.pathSegments.last));
          return _getSongFileFromFile(file);
        }).toList(),
      );

      return Result.ok(songFiles);
    } on Exception catch (e) {
      _log.severe('Error while reading a song content', e);

      return Result.error(e);
    }
  }

  @override
  Future<Result<SongFile?>> getSong(String filename) async {
    try {
      _log.info('Reading file \'$filename\'');

      if (!_isValidName(filename)) {
        return Result.error(ValidationException('Only letters, digits, underscores and hyphens are allowed.'));
      }

      final file = await _service.readFile(_songPath(_addExtension(filename)));
      return Result.ok(_getSongFileFromFile(file));
    } on FileSystemException {
      _log.warning('Failed to find file \'$filename\' in filesystem.');

      return Result.ok(null);
    } on Exception catch (e) {
      _log.severe('Error while reading the song \'$filename\' content', e);

      return Result.error(e);
    }
  }

  @override
  Future<Result<SongFile>> saveSong(SongFile song) async {
    try {
      _log.info('Saving song \'${song.filename}\'');

      if (!_isValidName(song.filename)) {
        return Result.error(ValidationException('Only letters, digits, underscores and hyphens are allowed.'));
      }

      _log.info('Verifying that directory \'$songDirPath\' exists');

      await _service.createDirectory(songDirPath);

      _log.info('Creating entry for song \'${song.filename}\'');

      final file = await _service.writeFile(_songPath(_addExtension(song.filename)), song.source);
      return Result.ok(_getSongFileFromFile(file));
    } on Exception catch (e) {
      _log.severe('Error while saving song \'${song.filename}\'', e);

      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> deleteSong(String filename) async {
    try {
      _log.info('Deleting song \'$filename\'');

      if (!_isValidName(filename)) {
        return Result.error(ValidationException('Only letters, digits, underscores and hyphens are allowed.'));
      }

      _log.info('Deleting entry for song \'$filename\'');

      await _service.deleteFile(_songPath(_addExtension(filename)));
      return Result.ok(null);
    } on Exception catch (e) {
      _log.severe('Error while deleting song \'$filename\'', e);

      return Result.error(e);
    }
  }

  bool _isValidName(String filename) {
    _log.info('Validating given filename: \'$filename\'');
    return _safeNamePattern.hasMatch(filename);
  }

  String _addExtension(String filename) => '$filename.${Constants.songFileExtension}';

  String _songPath(String path) => '$songDirPath${Platform.pathSeparator}$path';

  /// Converts a filesystem file into the repository model.
  ///
  /// The storage extension is stripped so callers keep working with stable
  /// logical names. File content is read here because [PersistenceService]
  /// deliberately exposes low-level filesystem handles.
  SongFile _getSongFileFromFile(File file) {
    final filename = path.basenameWithoutExtension(file.path);
    final source = file.readAsStringSync();

    return SongFile(filename: filename, source: source);
  }
}
