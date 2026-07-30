import 'package:atril/domain/models/chord/interval.dart';
import 'package:atril/domain/models/chord/key_signature.dart';
import 'package:atril/domain/models/chord/pitch_preference.dart';
import 'package:atril/domain/models/chord/transpose_direction.dart';

sealed class ChromaticTransposition {
  const ChromaticTransposition();
}

final class BySemitones extends ChromaticTransposition {
  const BySemitones(this.semitones, [this.pitchPreference = PitchPreference.automatic]);

  final int semitones;
  final PitchPreference pitchPreference;
}

final class ToKey extends ChromaticTransposition {
  const ToKey(this.key);

  final KeySignature key;
}

final class ByInterval extends ChromaticTransposition {
  const ByInterval(this.interval, this.direction, [this.pitchPreference = PitchPreference.automatic]);

  final Interval interval;
  final TransposeDirection direction;
  final PitchPreference pitchPreference;
}
