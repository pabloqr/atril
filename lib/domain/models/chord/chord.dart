import 'package:atril/domain/models/chord/note.dart';

/// A chord symbol split into its musical root, suffix, and optional bass note.
///
/// [extension] is intentionally stored as source notation rather than parsed
/// harmony. This preserves suffixes such as `m7`, `sus4`, or `add9` without
/// requiring the domain model to understand every possible chord vocabulary.
final class const Chord({
  /// The note on which the chord is built.
  required final Note root,

  /// The uninterpreted chord suffix, excluding [root] and [bass].
  final String? extension,

  /// The optional slash-chord bass note.
  final Note? bass,
}) {
  @override
  String toString() => '$root${extension ?? ''}${bass == null ? '' : '/$bass'}';
}
