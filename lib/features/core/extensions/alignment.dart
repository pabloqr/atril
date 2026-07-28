import 'package:flutter/widgets.dart';

extension AlignmentExtension on Alignment {
  Alignment get opposite => Alignment(-x, -y);
}
