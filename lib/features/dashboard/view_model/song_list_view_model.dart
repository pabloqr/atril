import 'dart:collection';

import 'package:atril/core/utils/command.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:atril/data/services/song/song_codec.dart';
import 'package:atril/domain/models/persistence/song_file.dart';
import 'package:atril/domain/models/settings/app_settings.dart';
import 'package:atril/domain/models/song.dart';
import 'package:flutter/foundation.dart';

final class SongListViewModel extends ChangeNotifier {
  SongListViewModel({required this._songRepository}) {
    load = Command0(_load)..execute();

    saveSong = Command2(_saveSong);
    renameSongFilename = Command3(_renameSong);
    deleteSong = Command1(_deleteSong);
  }

  static final List<SongFile> sampleSongs = <SongFile>[
    SongFile(
      filename: 'sample_amazing_grace',
      source:
          '{title: Amazing Grace}\n'
          '{artist: Traditional}\n'
          '{key: C}\n'
          '\n'
          '[C]Amazing [F]grace, how [C]sweet the sound\n'
          'That saved a [Am]wretch like [G]me\n'
          'I [C]once was [F]lost, but [C]now am found\n'
          'Was [Am]blind, but [G]now I [C]see',
    ),
    SongFile(
      filename: 'sample_house_of_the_rising_sun',
      source:
          '{title: House of the Rising Sun}\n'
          '{artist: Traditional}\n'
          '{key: Am}\n'
          '\n'
          'There [Am]is a [C]house in [D]New Or[F]leans\n'
          'They [Am]call the [C]Rising [E]Sun',
    ),
    SongFile(
      filename: 'sample_simple_blues',
      source:
          '{title: Simple Blues}\n'
          '{artist: Atril}\n'
          '{key: E}\n'
          '\n'
          '[E]Wake up this morning, feel the blues\n'
          '[A]Twelve bars later, back to [E]home\n'
          '[B7]Turn it around and [A]play it [E]again',
    ),
  ];

  final SongRepository _songRepository;

  late Command0<void> load;
  late Command2<void, String, String> saveSong;
  late Command3<void, String, String, String> renameSongFilename;
  late Command1<void, String> deleteSong;

  List<SongFile> _songs = [];

  String _searchQuery = '';
  LibrarySortOrder _sortOrder = LibrarySortOrder.title;

  UnmodifiableListView<SongFile> get songFiles => UnmodifiableListView(_songs);

  UnmodifiableListView<Song> get songs => UnmodifiableListView(_songs.map((song) => songCodec.decode(song.source)));

  UnmodifiableListView<SongFile> get filteredSongFiles {
    final songs = List.of(_songs);
    songs.sort(_compareSongs);

    final filteredSongs = songs.where(
      (song) => _searchQuery.isEmpty || _matchesQuery(songCodec.decode(song.source), _searchQuery.trim()),
    );

    return UnmodifiableListView(filteredSongs);
  }

  UnmodifiableListView<Song> get filteredSongs {
    final songs = List.of(_songs);
    songs.sort(_compareSongs);

    final filteredSongs = songs
        .map((song) => songCodec.decode(song.source))
        .where((song) => _searchQuery.isEmpty || _matchesQuery(song, _searchQuery.trim()));

    return UnmodifiableListView(filteredSongs);
  }

  String get searchQuery => _searchQuery;

  LibrarySortOrder get sortOrder => _sortOrder;

  set searchQuery(String searchQuery) {
    if (_searchQuery == searchQuery) return;

    _searchQuery = searchQuery;
    notifyListeners();
  }

  set sortOrder(LibrarySortOrder sortOrder) {
    if (_sortOrder == sortOrder) return;

    _sortOrder = sortOrder;
    notifyListeners();
  }

  Future<Result> _load() async {
    final songsResult = await _songRepository.getSongs();
    switch (songsResult) {
      case Ok<List<SongFile>>():
        _songs = songsResult.value;
        notifyListeners();
      case Error<List<SongFile>>():
    }

    if (_songs.isEmpty) {
      _songs = sampleSongs;
      notifyListeners();
    }

    return songsResult;
  }

  Future<Result> _saveSong(String name, String source) async {
    final createResult = await _songRepository.saveSong(SongFile(filename: name, source: source));
    switch (createResult) {
      case Ok<SongFile>():
        _songs.add(createResult.value);
        notifyListeners();
      case Error<SongFile>():
    }

    return createResult;
  }

  Future<Result> _renameSong(String oldFilename, String filename, String source) async {
    final deleteResult = await _songRepository.deleteSong(oldFilename);
    switch (deleteResult) {
      case Ok<void>():
        _songs.removeWhere((song) => song.filename == oldFilename);

        final createResult = await _songRepository.saveSong(SongFile(filename: filename, source: source));
        switch (createResult) {
          case Ok<SongFile>():
            _songs.add(createResult.value);
            notifyListeners();

            return createResult;
          case Error<SongFile>():
        }
      case Error<void>():
    }

    return deleteResult;
  }

  Future<Result> _deleteSong(String name) async {
    final deleteResult = await _songRepository.deleteSong(name);
    switch (deleteResult) {
      case Ok<void>():
        _songs.removeWhere((song) => song.filename == name);
        notifyListeners();
      case Error<void>():
    }

    return deleteResult;
  }

  int _compareSongs(SongFile a, SongFile b) {
    final (metadataA, metadataB) = (songCodec.decode(a.source).metadata, songCodec.decode(b.source).metadata);

    final (primaryA, primaryB, secondaryA, secondaryB) = switch (_sortOrder) {
      LibrarySortOrder.title => (metadataA.title, metadataB.title, metadataA.artist, metadataB.artist),
      LibrarySortOrder.artist => (metadataA.artist, metadataB.artist, metadataA.title, metadataB.title),
    };

    final primaryComparison = _compareMetadata(primaryA, primaryB);
    if (primaryComparison != 0) {
      return primaryComparison;
    }

    final secondaryComparison = _compareMetadata(secondaryA, secondaryB);
    if (secondaryComparison != 0) {
      return secondaryComparison;
    }

    return a.filename.compareTo(b.filename);
  }

  int _compareMetadata(String? a, String? b) {
    final normalizedA = a?.trim() ?? '';
    final normalizedB = b?.trim() ?? '';

    if (normalizedA.isEmpty != normalizedB.isEmpty) {
      return normalizedA.isEmpty ? 1 : -1;
    }

    return normalizedA.compareTo(normalizedB);
  }

  bool _matchesQuery(Song song, String query) {
    return (song.metadata.title ?? '').contains(query) || (song.metadata.artist ?? '').contains(query);
  }
}
