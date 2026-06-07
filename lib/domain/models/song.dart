/// Public exports for the song domain model.
///
/// Import this file when working with songs at the domain boundary instead of
/// importing individual implementation files one by one. It exposes the song
/// aggregate, its logical line variants, directive types, and extracted
/// metadata.
library;

export 'song/directive.dart';
export 'song/directive_type.dart';
export 'song/line.dart';
export 'song/metadata.dart';
export 'song/song.dart';
