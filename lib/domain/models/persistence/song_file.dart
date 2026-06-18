/// Source-level song document handled by persistence repositories.
///
/// [name] is the storage identifier without any repository-added extension.
/// [source] is the complete ChordPro text as read from or written to disk.
final class SongFile {
  SongFile({required this.name, required this.source});

  /// Stable file-oriented song name, not necessarily the ChordPro `{title}`.
  final String name;

  /// Complete ChordPro source text.
  final String source;
}
