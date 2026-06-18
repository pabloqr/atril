import 'package:atril/core/utils/result.dart';
import 'package:atril/data/services/persistence/file_picker_service.dart';
import 'package:atril/domain/models/persistence/song_file.dart';

/// Repository for user-selected files outside Atril's local song library.
abstract final class ExternalFileRepository {
  /// Imports a UTF-8 ChordPro-compatible file as an unsaved [SongFile].
  ///
  /// Returns `Ok(null)` when the user cancels selection.
  Future<Result<SongFile?>> importFile();

  /// Exports a song through the platform file picker.
  Future<Result<void>> exportFile();
}

/// [ExternalFileRepository] backed by a platform [FilePickerService].
final class ExternalFileRepositoryImpl implements ExternalFileRepository {
  ExternalFileRepositoryImpl({required this._service});

  final FilePickerService _service;

  @override
  Future<Result<SongFile?>> importFile() async {
    try {
      final result = await _service.pickFile();
      switch (result) {
        case Ok<SongFile?>():
          return Result.ok(result.value);
        case Error<SongFile?>():
          return Result.error(result.error);
      }
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> exportFile() async {
    // TODO: implement exportFile
    throw UnimplementedError();
  }
}
