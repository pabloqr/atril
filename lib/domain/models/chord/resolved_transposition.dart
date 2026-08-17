import 'package:atril/domain/models/chord/accidental.dart';
import 'package:atril/domain/models/chord/key_signature.dart';

/// The fully specified movement used to transpose spelled musical notes.
///
/// [diatonicSteps] selects the destination note letter, while
/// [chromaticSemitones] selects its sounding pitch. Keeping both values avoids
/// losing interval spelling when two notes share the same pitch class. When it
/// can be determined, [targetKey] supplies the destination key and
/// [preferredAccidentalFamily] records the accidental family to prefer for
/// enharmonic fallbacks.
final class ResolvedTransposition({
  /// Signed number of diatonic letter steps to apply.
  required final int diatonicSteps,

  /// Signed number of chromatic semitones to apply.
  required final int chromaticSemitones,

  /// Destination key, or `null` when the source key is unknown.
  final KeySignature? targetKey,

  /// Accidental family to prefer when a note requires enharmonic selection.
  final Accidental? preferredAccidentalFamily,
});
