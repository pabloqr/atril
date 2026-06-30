import 'dart:io';

import 'package:atril/core/utils/exceptions.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:atril/data/services/persistence/persistence_service.dart';
import 'package:atril/domain/models/persistence/song_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory tempDir;
  late SongRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('atril_song_repository_test_');
    repository = SongRepositoryImpl(
      service: LocalPersistenceService(baseDirPath: tempDir.path),
      songDirPath: 'songs',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SongRepositoryImpl', () {
    test('saves songs using the canonical extension and strips it when reading', () async {
      final saveResult = await repository.saveSong(SongFile(filename: 'my_song', source: '{title: My Song}'));

      expect(saveResult, isA<Ok<SongFile>>());
      final saved = (saveResult as Ok<SongFile>).value;
      expect(saved.filename, 'my_song');
      expect(saved.source, '{title: My Song}');
      expect(await File(path.join(tempDir.path, 'songs', 'my_song.cho')).readAsString(), '{title: My Song}');
    });

    test('returns only supported song files sorted by path', () async {
      await Directory(path.join(tempDir.path, 'songs')).create(recursive: true);
      await File(path.join(tempDir.path, 'songs', 'b_song.cho')).writeAsString('{title: B}');
      await File(path.join(tempDir.path, 'songs', 'a_song.cho')).writeAsString('{title: A}');
      await File(path.join(tempDir.path, 'songs', 'notes.txt')).writeAsString('ignore me');

      final result = await repository.getSongs();

      expect(result, isA<Ok<List<SongFile>>>());
      expect((result as Ok<List<SongFile>>).value.map((song) => song.filename), ['a_song', 'b_song']);
    });

    test('deletes canonical song files and treats missing files as success', () async {
      await repository.saveSong(SongFile(filename: 'my_song', source: 'source'));

      final firstDelete = await repository.deleteSong('my_song');
      final secondDelete = await repository.deleteSong('my_song');

      expect(firstDelete, isA<Ok<void>>());
      expect(secondDelete, isA<Ok<void>>());
      expect(await File(path.join(tempDir.path, 'songs', 'my_song.cho')).exists(), isFalse);
    });

    test('rejects unsafe file names without touching the filesystem', () async {
      final saveResult = await repository.saveSong(SongFile(filename: '../escape', source: 'source'));
      final deleteResult = await repository.deleteSong('../escape');

      expect(saveResult, isA<Error<SongFile>>().having((result) => result.error, 'error', isA<ValidationException>()));
      expect(deleteResult, isA<Error<void>>().having((result) => result.error, 'error', isA<ValidationException>()));
      expect(await Directory(path.join(tempDir.path, 'songs')).exists(), isFalse);
    });

    test('wraps filesystem failures in Result.error', () async {
      final result = await repository.getSongs();

      expect(
        result,
        isA<Error<List<SongFile>>>().having((result) => result.error, 'error', isA<FileSystemException>()),
      );
    });
  });
}
