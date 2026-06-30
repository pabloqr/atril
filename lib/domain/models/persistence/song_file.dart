/// Source-level song document handled by persistence repositories.
///
/// [filename] is the storage identifier without any repository-added extension.
/// [source] is the complete ChordPro text as read from or written to disk.
final class SongFile {
  SongFile({required this.filename, required this.source});

  /// Stable file-oriented song name, not necessarily the ChordPro `{title}`.
  final String filename;

  /// Complete ChordPro source text.
  final String source;
}
