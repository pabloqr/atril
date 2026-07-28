import 'package:atril/domain/models/song/directive_type.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

extension DirectiveTypePresentation on DirectiveType {
  IconData get icon => switch (this) {
    DirectiveType.title => Symbols.title_rounded,
    DirectiveType.artist => Symbols.artist_rounded,
    DirectiveType.key => Symbols.music_note_rounded,
    DirectiveType.capo => Symbols.swap_vert_rounded,
    DirectiveType.comment => Symbols.comment_rounded,
    _ => Symbols.question_mark_rounded,
  };
}
