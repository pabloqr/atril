import 'dart:convert';

import 'package:atril/core/utils/patterns.dart';
import 'package:atril/domain/models/chord/chord.dart';
import 'package:atril/domain/models/chord/note.dart';

/// The shared codec for Atril's supported chord notation.
const chordCodec = ChordCodec();

/// Converts between [Chord] objects and compact chord symbols.
///
/// The root and slash bass are parsed as [Note] values. The extension remains
/// uninterpreted so notation outside Atril's harmonic model can round-trip.
final class ChordCodec extends Codec<Chord, String> {
  /// Creates a stateless chord codec.
  const ChordCodec();

  @override
  ChordEncoder get encoder => const ChordEncoder();

  @override
  ChordDecoder get decoder => const ChordDecoder();
}

/// Serializes a [Chord] as `root + extension + optional slash bass`.
final class ChordEncoder extends Converter<Chord, String> {
  /// Creates a stateless chord encoder.
  const ChordEncoder();

  /// Converts [chord] to its compact source representation.
  @override
  String convert(Chord chord) {
    final buffer = StringBuffer(chord.root.symbol);
    if (chord.extension != null) buffer.write(chord.extension);
    if (chord.bass != null) buffer.write('/${chord.bass!.symbol}');
    return buffer.toString();
  }
}

/// Parses complete chord symbols accepted by [Patterns.chord].
final class ChordDecoder extends Converter<String, Chord> {
  /// Creates a stateless chord decoder.
  const ChordDecoder();

  /// Parses [input] or throws [FormatException] when the full string is invalid.
  @override
  Chord convert(String input) {
    final match = Patterns.chord.firstMatch(input);
    if (match == null) {
      throw FormatException('Invalid chord string: "$input"');
    }

    final root = Note.parse(match.group(1)!);
    final ext = match.group(2)!.isEmpty ? null : match.group(2);
    final bassSymbol = match.group(3);
    final bass = bassSymbol != null ? Note.parse(bassSymbol) : null;

    return Chord(root: root, extension: ext, bass: bass);
  }
}
