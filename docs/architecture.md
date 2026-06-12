# Atril architecture

This page explains the boundaries and data flow of Atril's pure Dart song-processing core. UI, persistence, and platform integration build on these components but should not duplicate their parsing or music rules.

## Main boundaries

### Domain models

`lib/domain/models` contains data structures without Flutter dependencies:

- `Song` is the aggregate returned by parsing. It contains ordered logical lines, derived metadata, and parser diagnostics.
- `Line` has three variants: directives, lyrics with positioned chord anchors, and explicit empty lines.
- `Chord` separates a root note, an uninterpreted extension, and an optional slash bass.
- `Note` is an enum containing all 21 spellings formed by seven note letters and the supported flat, natural, and sharp accidentals. Enharmonic notes such as `C#` and `Db` therefore remain distinct even though they share a pitch class. `Note.lookup` resolves a `(NoteLetter, Accidental)` pair to its canonical enum value.
- `Interval` is an enum containing the closed set of intervals supported by Atril. Each value stores both a diatonic distance and a semitone distance so transposition can preserve musical spelling.

The models do not validate source offsets, chord suffix semantics, capo ranges, or every ChordPro rule. Validation belongs at input boundaries.

### Codecs

`lib/data/services/chord/chord_codec.dart` converts between compact chord notation and `Chord`. It parses the root and slash bass but deliberately preserves the extension as text.

`lib/data/services/song/song_codec.dart` converts between ChordPro source and `Song`. Decoding is tolerant: malformed constructs produce `ParseIssue` entries and remain visible as lyric text where recovery is possible. Encoding emits canonical LF-separated ChordPro from the parsed model; it does not reproduce original whitespace or line endings.

### Source editing

`SourceEditor` performs small edits directly against source text. It is separate from `SongCodec` because editor actions must preserve unrelated whitespace, unknown directives, and the existing newline convention.

Each operation receives and returns a `SourceFragment`, which combines the complete source with the caret or range the UI should select after applying the edit. Header directives are deduplicated and inserted in the order `title`, `artist`, `key`, `capo`. Chord insertion is restricted to a single non-directive line.

### Transposition

`Transposer` transforms parsed domain objects rather than source strings:

1. The interval's diatonic distance chooses the destination letter.
2. Its semitone distance chooses the destination pitch class.
3. The difference determines the accidental.
4. Song transposition rebuilds lyric-line chord anchors while preserving lyric text and offsets.

Only natural notes, single flats, and single sharps are supported. A requested spelling that needs a double accidental throws `ArgumentError`; callers must choose a supported interval or surface that limitation.

### Capo intervals

`Interval.lookup[capo]` maps capo frets 0 through 12 to Atril's canonical simple intervals. The tritone at fret 6 is represented as an augmented fourth. Values outside that octave return `null` because the current interval model has no compound quantities.

The returned interval is the capo's upward sounding displacement. To add a capo while preserving the song's sounding pitch, transpose the written chords downward by that interval:

```dart
final interval = Interval.lookup[capo];
if (interval == null) {
  throw RangeError.range(capo, 0, 12, 'capo');
}
final rewrittenSong = const Transposer().transposeSong(
  song,
  interval,
  TransposeDirection.down,
);
```

Changing the `{capo: ...}` directive remains a separate source-editing operation.

## Parse and preview flow

1. The editor owns the original ChordPro string.
2. `songCodec.decode` normalizes line endings and parses each logical line.
3. Recognized directives become `DirectiveLine` values; lyric lines have chord markers removed and represented as `ChordAnchor` offsets.
4. Recoverable errors are collected in `Song.issues` without stopping the rest of the document.
5. `Song` derives `Metadata` from its directive lines.
6. The UI renders `Song.lines` and maps diagnostics back to the source through `SourceLocation`.

The parsed model is a preview and transformation representation, not a lossless syntax tree. Source-preserving editor actions must operate through `SourceEditor`.

## Serialization flow

`songCodec.encode` serializes logical lines in order. Directive names are normalized, line endings become LF, and chord anchors are inserted at their lyric offsets. Out-of-range or decreasing offsets are clamped defensively so externally constructed models remain serializable.

Parser diagnostics are not serialized because they describe source defects rather than song content.

## Dependency direction

The intended dependency direction is:

```text
UI / persistence
      |
      v
data services (codecs, source editing, transposition)
      |
      v
domain models
      |
      v
core syntax helpers
```

Domain models must remain independent of Flutter and data-service implementations. Data services may coordinate models and shared syntax helpers but should not depend on widgets or storage.
