import 'package:atril/domain/models/chord/note.dart';

final class Chord {
  Chord({required this.root, this.ext, this.bass});

  final Note root;
  final String? ext;
  final Note? bass;
}
