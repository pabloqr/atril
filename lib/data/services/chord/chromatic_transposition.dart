import 'package:atril/domain/models/chord/interval.dart';
import 'package:atril/domain/models/chord/key_signature.dart';
import 'package:atril/domain/models/chord/pitch_preference.dart';
import 'package:atril/domain/models/chord/transpose_direction.dart';

/// Describes how a chromatic transposition is requested.
///
/// Each subtype carries the input required by one supported transposition
/// mode. Consumers can switch exhaustively over the sealed hierarchy while
/// sharing the same song and chord traversal.
sealed class const ChromaticTransposition();

/// Requests a chromatic transposition by a signed semitone distance.
///
/// Positive values transpose upward and negative values transpose downward.
/// When no source key is available, [pitchPreference] controls the enharmonic
/// spelling used by the transposer.
final class const BySemitones(
  /// The signed number of semitones by which pitches are shifted.
  final int semitones, [

  /// The fallback enharmonic spelling preference.
  ///
  /// A resolved target key takes precedence over this value.
  final PitchPreference pitchPreference = PitchPreference.automatic,
]) extends ChromaticTransposition;

/// Requests a chromatic transposition to a specific target key.
///
/// The corresponding key and note algorithms are not yet implemented by the
/// transposition service.
final class const ToKey(
  /// The requested destination key.
  final KeySignature key,
) extends ChromaticTransposition;

/// Requests a transposition using a named interval and direction.
///
/// Interval requests currently use the temporary spelled-interval algorithm
/// and will adopt the shared chromatic algorithm in a later implementation.
final class const ByInterval(
  /// The interval that determines the transposition distance.
  final Interval interval,

  /// The direction in which [interval] is applied.
  final TransposeDirection direction, [

  /// The fallback enharmonic spelling preference.
  ///
  /// A resolved target key takes precedence over this value.
  final PitchPreference pitchPreference = PitchPreference.automatic,
]) extends ChromaticTransposition;
