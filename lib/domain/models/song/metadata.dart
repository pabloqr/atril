import 'package:atril/domain/models/chord/chord.dart';

/// Descriptive information associated with a song.
///
/// [Metadata] stores the normalized metadata fields that the domain currently
/// understands directly, plus containers for repeated comments and unknown or
/// format-specific fields.
///
/// This class is deliberately passive: it does not parse directive names,
/// validate musical values, derive missing values, or enforce formatting rules.
/// The object represents metadata that has already been extracted by another
/// layer.
final class Metadata {
  /// Creates a metadata object.
  ///
  /// All fields are optional. [comments] and [misc] default to empty constant
  /// collections when omitted.
  Metadata({this.title, this.artist, this.key, this.capo, this.comments = const [], this.misc = const {}});

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
  /// Multiple comments are preserved in order. The list is stored as received;
  /// callers that require immutability should pass an immutable list or avoid
  /// mutating the original list after construction.
  final List<String> comments;

  /// Metadata entries that are not represented by the dedicated fields.
  ///
  /// Keys are directive or source field names. Values are lists so repeated
  /// fields can be preserved without overwriting earlier values.
  ///
  /// The map and its value lists are stored as received; this class does not
  /// create defensive copies.
  final Map<String, List<String>> misc;
}
