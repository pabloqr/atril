import 'dart:convert';

import 'package:atril/core/config/constants.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/domain/models/persistence/song_file.dart';
import 'package:file_picker/file_picker.dart';

/// Platform file picker boundary for importing and exporting ChordPro files.
abstract final class FilePickerService {
  /// Lets the user select a UTF-8 ChordPro-compatible file.
  ///
  /// Returns `Ok(null)` when the user cancels selection.
  Future<Result<SongFile?>> pickFile();

  /// Saves a ChordPro-compatible file through the platform picker.
  Future<Result<void>> saveFile();
}

/// [FilePickerService] implementation backed by the `file_picker` plugin.
final class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<Result<SongFile?>> pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: Constants.allowedFileExtensions,
    );

    if (files.isNotEmpty) {
      try {
        final file = files.single;
        final bytes = await file.readAsBytes();

        return Result.ok(SongFile(filename: file.name, source: utf8.decode(bytes, allowMalformed: false)));
      } on Exception catch (e) {
        return Result.error(e);
      }
    }

    return Result.ok(null);
  }

  @override
  Future<Result<void>> saveFile() async {
    // TODO: implement saveFile
    throw UnimplementedError();
  }
}
