import 'dart:io';

import 'package:atril/core/config/constants.dart';
import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/services/persistence/persistence_service.dart';
import 'package:atril/domain/models/persistence/song_file.dart';
import 'package:path/path.dart' as path;

/// Repository for Atril's local ChordPro song library.
///
/// The repository works with source files rather than parsed song aggregates:
/// parsing, validation of ChordPro content, and metadata extraction belong to
/// the song codec and UI flow.
abstract final class SongRepository {
  /// Reads every supported song file from the configured library directory.
  Future<Result<List<SongFile>>> getSongs();

  /// Validates the storage name and writes the song using Atril's canonical
  /// extension.
  Future<Result<SongFile>> saveSong(SongFile song);

  /// Deletes the canonical file for [name].
  Future<Result<void>> deleteSong(String name);
}

/// File-backed [SongRepository] using a [PersistenceService].
final class SongRepositoryImpl implements SongRepository {
  const SongRepositoryImpl({required this._service, this.songDirPath = Constants.songDirPath});

  static final RegExp _safeNamePattern = RegExp(r'^[A-Za-z0-9_-]+$');

  final PersistenceService _service;

  final String songDirPath;

  @override
  Future<Result<List<SongFile>>> getSongs() async {
    try {
      final entities = await _service.listDirectory(songDirPath);

      final songEntities = entities.where((entity) {
        final extension = path.extension(entity.path).substring(1);
        return Constants.allowedFileExtensions.contains(extension);
      }).toList();
      songEntities.sort(((a, b) => a.path.compareTo(b.path)));

      final songFiles = await Future.wait(
        songEntities.map((entity) async {
          final file = await _service.readFile(_songPath(entity.uri.pathSegments.last));
          return _getSongFileFromFile(file);
        }).toList(),
      );

      return Result.ok(songFiles);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<SongFile>> saveSong(SongFile song) async {
    try {
      if (!_isValidName(song.name)) {
        return Result.error(ValidationException('Only letters, digits, underscores and hyphens are allowed.'));
      }

      await _service.createDirectory(songDirPath);

      final file = await _service.writeFile(_songPath(_addExtension(song.name)), song.source);
      return Result.ok(_getSongFileFromFile(file));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> deleteSong(String name) async {
    try {
      if (!_isValidName(name)) {
        return Result.error(ValidationException('Only letters, digits, underscores and hyphens are allowed.'));
      }

      await _service.deleteFile(_songPath(_addExtension(name)));
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  bool _isValidName(String name) => _safeNamePattern.hasMatch(name);

  String _addExtension(String name) => '$name.${Constants.songFileExtension}';

  String _songPath(String path) => '$songDirPath${Platform.pathSeparator}$path';

  /// Converts a filesystem file into the repository model.
  ///
  /// The storage extension is stripped so callers keep working with stable
  /// logical names. File content is read here because [PersistenceService]
  /// deliberately exposes low-level filesystem handles.
  SongFile _getSongFileFromFile(File file) {
    final name = path.basenameWithoutExtension(file.path);
    final source = file.readAsStringSync();

    return SongFile(name: name, source: source);
  }
}
