import 'dart:io';

import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:atril/data/services/persistence/persistence_service.dart';
import 'package:atril/domain/models/settings/app_settings.dart';
import 'package:atril/features/dashboard/view_model/song_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory tempDir;
  late SongRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('atril_song_list_view_model_test_');
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

  group('SongListViewModel', () {
    test('loads repository songs and filters by title or artist', () async {
      await _writeSong(tempDir, 'b', '{title: Beta}\n{artist: Zed}');
      await _writeSong(tempDir, 'a', '{title: Alpha}\n{artist: Ann}');
      final viewModel = SongListViewModel(songRepository: repository);
      await _waitForInitialLoad(viewModel);

      expect(viewModel.songFiles.map((song) => song.filename), ['a', 'b']);
      expect(viewModel.filteredSongFiles.map((song) => song.filename), ['a', 'b']);

      viewModel.searchQuery = 'Zed';

      expect(viewModel.filteredSongFiles.map((song) => song.filename), ['b']);
      expect(viewModel.filteredSongs.single.metadata.artist, 'Zed');
    });

    test('falls back to sample songs when repository returns an empty list', () async {
      await Directory(path.join(tempDir.path, 'songs')).create(recursive: true);
      final viewModel = SongListViewModel(songRepository: repository);
      await _waitForInitialLoad(viewModel);

      expect(viewModel.songFiles, hasLength(SongListViewModel.sampleSongs.length));
      expect(viewModel.songFiles.first.filename, SongListViewModel.sampleSongs.first.filename);
    });

    test('sorts by artist with title and filename tie breakers', () async {
      await _writeSong(tempDir, 'z', '{title: Same}\n{artist: Duo}');
      await _writeSong(tempDir, 'a', '{title: Same}\n{artist: Duo}');
      await _writeSong(tempDir, 'm', '{title: Other}\n{artist: Duo}');
      await _writeSong(tempDir, 'untitled', 'No metadata');
      final viewModel = SongListViewModel(songRepository: repository);
      await _waitForInitialLoad(viewModel);

      viewModel.sortOrder = LibrarySortOrder.artist;

      expect(viewModel.filteredSongFiles.map((song) => song.filename), ['m', 'a', 'z', 'untitled']);
    });

    test('save, rename, and delete commands update local list after repository success', () async {
      await Directory(path.join(tempDir.path, 'songs')).create(recursive: true);
      final viewModel = SongListViewModel(songRepository: repository);
      await _waitForInitialLoad(viewModel);

      await viewModel.saveSong.execute('created', '{title: Created}');
      await viewModel.renameSongFilename.execute('created', 'renamed', '{title: Renamed}');
      await viewModel.deleteSong.execute('renamed');

      expect(
        viewModel.songFiles.map((song) => song.filename),
        SongListViewModel.sampleSongs.map((song) => song.filename),
      );
      expect(await File(path.join(tempDir.path, 'songs', 'created.cho')).exists(), isFalse);
      expect(await File(path.join(tempDir.path, 'songs', 'renamed.cho')).exists(), isFalse);
    });

    test('does not mutate local list when repository rejects unsafe names', () async {
      await Directory(path.join(tempDir.path, 'songs')).create(recursive: true);
      final viewModel = SongListViewModel(songRepository: repository);
      await _waitForInitialLoad(viewModel);
      final originalFilenames = viewModel.songFiles.map((song) => song.filename).toList();

      await viewModel.saveSong.execute('../created', '{title: Created}');
      await viewModel.deleteSong.execute('../${originalFilenames.first}');

      expect(viewModel.songFiles.map((song) => song.filename), originalFilenames);
      expect(viewModel.saveSong.error, isTrue);
      expect(viewModel.deleteSong.error, isTrue);
    });
  });
}

Future<void> _writeSong(Directory tempDir, String filename, String source) async {
  await Directory(path.join(tempDir.path, 'songs')).create(recursive: true);
  await File(path.join(tempDir.path, 'songs', '$filename.cho')).writeAsString(source);
}

Future<void> _waitForInitialLoad(SongListViewModel viewModel) async {
  while (viewModel.load.running) {
    await Future<void>.delayed(Duration.zero);
  }
}
