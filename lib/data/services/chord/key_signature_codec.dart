import 'dart:convert';

import 'package:atril/core/utils/patterns.dart';
import 'package:atril/domain/models/chord/key_mode.dart';
import 'package:atril/domain/models/chord/key_signature.dart';
import 'package:atril/domain/models/chord/note.dart';

const keySignatureCodec = KeySignatureCodec();

final class const KeySignatureCodec() extends Codec<KeySignature, String> {
  @override
  KeySignatureEncoder get encoder => const KeySignatureEncoder();

  @override
  KeySignatureDecoder get decoder => const KeySignatureDecoder();
}

final class const KeySignatureEncoder() extends Converter<KeySignature, String> {
  @override
  String convert(KeySignature key) => key.toString();
}

final class const KeySignatureDecoder() extends Converter<String, KeySignature> {
  @override
  KeySignature convert(String input) {
    final match = Patterns.key.firstMatch(input);
    if (match == null) throw FormatException('Invalid key signature string: "$input"');

    final tonic = match.namedGroup('root')!;
    final extension = match.namedGroup('extension') ?? '';

    final mode = KeyMode.lookupByAlias[extension];
    if (mode == null) throw FormatException('Invalid key signature mode: "$extension"');

    final key = KeySignature.lookup[(Note.parse(tonic), mode)];
    if (key == null) throw FormatException('Invalid key signature string: "$input"');

    return key;
  }
}
