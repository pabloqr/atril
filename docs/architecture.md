# Atril architecture

This page explains the boundaries and data flow of Atril's Dart application
core. UI, persistence, and platform integration build on these components but
should not duplicate their parsing, storage, or music rules.

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

Only natural notes, single flats, and single sharps are supported. A requested spelling that needs a double accidental throws `TranspositionException`; callers must choose a supported interval or surface that limitation.

### Result and command flow

`lib/core/utils/result.dart` defines the explicit operation result used by
repositories and platform services:

- `Ok<T>` carries the operation value.
- `Error<T>` carries an `Exception` that the caller can display, map, retry, or
  rethrow.

This keeps expected user-facing failures, such as invalid names or missing
files, out of exception-driven UI control flow. Lower-level services may still
throw; repository methods catch those exceptions and return `Result.error`.

`Command` wraps asynchronous view-model actions. It exposes running,
completion, error, and latest-result state through `ChangeNotifier`, and it
ignores re-entrant executions while the previous execution is still running.
The action itself remains responsible for returning `Result`.

`ResultUtils.unwrapOrThrow` exists only as an adapter for call sites that still
need exception semantics. New repository consumers should usually switch on
`Ok` and `Error` directly.

### Persistence

`lib/domain/models/persistence/SongFile` represents a source-level document:

- `name` is the storage identifier used by repositories, separate from the
  ChordPro `{title}` directive.
- `source` is the complete ChordPro text.

`PersistenceService` is the low-level filesystem boundary. Its local
implementation resolves paths relative to a platform base directory and returns
`dart:io` handles. It does not parse ChordPro, validate user-facing names, or
decide which extensions belong to the song library.

`SongRepository` is the local library boundary. It:

1. Lists files from `Constants.songDirPath`.
2. Keeps only files whose extensions appear in
   `Constants.allowedFileExtensions`.
3. Sorts them by path for stable presentation.
4. Reads each file and converts it to `SongFile`, stripping the storage
   extension from the logical name.
5. Returns failures as `Result.error`.

Saving and deleting validate the logical name with the repository's safe-name
pattern. Only ASCII letters, digits, underscores, and hyphens are accepted.
Saved songs use the canonical extension from `Constants.songFileExtension`.

### External files

`FilePickerService` is the platform boundary for user-selected files outside
Atril's managed library. `ExternalFileRepository` wraps that service so the rest
of the app can work with `Result<SongFile?>` instead of plugin types.

Import returns:

- `Ok(SongFile)` when a UTF-8 file is selected and decoded.
- `Ok(null)` when the user cancels the picker.
- `Error` when selection or decoding fails.

Export is currently a contract only: `FilePickerService.saveFile` and
`ExternalFileRepository.exportFile` are not implemented yet. Code and
documentation must not present external export as complete until those methods
write a selected file and return `Result`.

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
UI / view models
      |
      v
commands
      |
      v
repositories
      |
      v
data services (codecs, source editing, transposition, persistence adapters)
      |
      v
domain models
      |
      v
core syntax helpers
```

Domain models must remain independent of Flutter and data-service
implementations. Data services may coordinate models, shared syntax helpers, and
platform adapters but should not depend on widgets. Repositories translate
service-level behavior into application-level `Result` contracts.
