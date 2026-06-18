import 'package:atril/domain/models/chord/chord.dart';
import 'package:atril/domain/models/song/directive_type.dart';
import 'package:atril/domain/models/song/line.dart';

/// Descriptive information associated with a song.
///
/// [Metadata] stores the normalized metadata fields that the domain currently
/// understands directly, plus containers for repeated comments and unknown or
/// format-specific fields.
///
/// This class interprets known directive names and stores unrecognized entries
/// in [misc]. Validation of musical values and source-specific alias handling
/// belongs in the parser or editing layer.
final class Metadata {
  /// Creates a metadata object.
  ///
  /// Known directives are assigned to their dedicated fields using
  /// [DirectiveType]. Repeated comments are preserved in order, and unknown
  /// directives are collected in [misc].
  ///
  /// When the same single-value directive appears more than once, the first
  /// value that can be converted to the expected type wins. Later duplicate
  /// values are ignored for dedicated fields.
  factory Metadata({List<DirectiveLine> directives = const []}) {
    String? title;
    String? artist;
    Chord? key;
    int? capo;
    final comments = <String>[];
    final misc = <String, List<String>>{};

    for (final directive in directives) {
      final type = DirectiveType.lookup[directive.name];
      final value = directive.directive.value;

      switch (type) {
        case DirectiveType.title:
          title ??= _stringValue(value);
        case DirectiveType.artist:
          artist ??= _stringValue(value);
        case DirectiveType.key:
          key ??= _chordValue(value);
        case DirectiveType.capo:
          capo ??= _intValue(value);
        case DirectiveType.comment:
          final comment = _stringValue(value);
          if (comment != null) comments.add(comment);
        case DirectiveType.unknown:
        case null:
          final miscValue = _stringValue(value);
          if (miscValue != null) {
            misc.putIfAbsent(directive.name, () => <String>[]).add(miscValue);
          }
      }
    }

    return Metadata._(
      title: title,
      artist: artist,
      key: key,
      capo: capo,
      comments: List.unmodifiable(comments),
      misc: Map.unmodifiable(misc.map((k, v) => MapEntry(k, List<String>.unmodifiable(v)))),
    );
  }

  const Metadata._({
    required this.title,
    required this.artist,
    required this.key,
    required this.capo,
    required this.comments,
    required this.misc,
  });

  /// The song title, when known.
  final String? title;

  /// The credited artist or performer, when known.
  final String? artist;

  /// The musical key of the song, when known.
  ///
  /// The key is represented as a [Chord] so the model can reuse the chord
  /// spelling already used elsewhere in the domain. This does not imply that
  /// every chord extension is musically meaningful as a key; validation belongs
  /// in the parser or editing layer.
  final Chord? key;

  /// The capo fret number, when specified.
  ///
  /// This model does not enforce a valid range. Code that accepts user input or
  /// parses external files should reject invalid fret numbers before creating
  /// the metadata object.
  final int? capo;

  /// Free-form comments associated with the song.
  ///
  /// Multiple comments are preserved in order.
  final List<String> comments;

  /// Metadata entries that are not represented by the dedicated fields.
  ///
  /// Keys are normalized directive names. Values are lists so repeated
  /// fields can be preserved without overwriting earlier values.
  ///
  /// The map and its value lists are immutable.
  final Map<String, List<String>> misc;

  static String? _stringValue(Object? value) => switch (value) {
    null => null,
    String() => value,
    _ => value.toString(),
  };

  static Chord? _chordValue(Object? value) => switch (value) {
    Chord() => value,
    _ => null,
  };

  static int? _intValue(Object? value) => switch (value) {
    int() => value,
    String() => int.tryParse(value),
    _ => null,
  };
}
