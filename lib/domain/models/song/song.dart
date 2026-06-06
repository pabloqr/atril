import 'package:atril/domain/models/song/line.dart';
import 'package:atril/domain/models/song/metadata.dart';

/// A complete song represented as ordered logical lines plus extracted metadata.
///
/// [Song] is the aggregate root for the song domain model. It preserves the
/// document body as an ordered list of [Line] objects and exposes a [Metadata]
/// object for information that has been extracted or assigned separately.
///
/// The current constructor does not derive [metadata] from [lines]. It creates
/// an empty [Metadata] instance regardless of which directive lines are present.
/// Until metadata extraction is implemented, code that needs populated metadata
/// must supply or compute it outside this class.
final class Song {
  // TODO: Get metadata from lines
  /// Creates a song from an ordered sequence of logical [lines].
  ///
  /// The provided list is copied into an unmodifiable list, so later mutations
  /// to the argument do not change [lines]. The [Line] objects themselves are
  /// not deep-copied.
  Song({List<Line> lines = const []})
    : metadata = Metadata(directives: lines.whereType<DirectiveLine>().toList()),
      lines = List.unmodifiable(lines);

  /// Metadata associated with the song.
  ///
  /// At the moment this is always initialized as empty metadata by the
  /// constructor. It is not inferred from directive lines yet.
  final Metadata metadata;

  /// The song body as ordered logical lines.
  ///
  /// The list is unmodifiable and preserves the order supplied to the
  /// constructor.
  final List<Line> lines;
}
