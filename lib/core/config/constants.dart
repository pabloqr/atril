/// Shared application constants used by repository and platform boundaries.
abstract final class Constants {
  /// Relative directory, under the platform documents root, where saved songs
  /// are stored.
  static const String songDirPath = 'song';

  /// Extensions accepted when reading ChordPro-compatible files.
  static const List<String> allowedFileExtensions = ['cho', 'crd', 'chopro', 'chord', 'pro'];

  /// Canonical extension used when Atril writes a local song file.
  static const String songFileExtension = 'cho';
}
