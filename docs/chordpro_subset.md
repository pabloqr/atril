# Supported ChordPro subset

This page is the reference for the ChordPro syntax currently recognized by Atril. Unsupported syntax may be preserved as text, but it must not be assumed to have ChordPro semantics.

## Documents

- Input may use LF, CRLF, or CR line endings.
- Parsing normalizes all line endings into logical lines.
- Encoding always joins logical lines with LF.
- Blank or whitespace-only source lines become explicit `EmptyLine` values.
- Local library and import flows currently accept files with `cho`, `crd`,
  `chopro`, `chord`, or `pro` extensions.

## Directives

A recognized directive occupies a complete line and uses one of these forms:

```text
{name}
{name: value}
```

Directive names start with an ASCII lowercase letter and may continue with lowercase letters, digits, `_`, or `-`. Leading and trailing horizontal whitespace around the directive is accepted. Directive names are normalized to lowercase in the domain model.

### Supported names

| Name | Value represented as | Preferred location | Repeated values |
| --- | --- | --- | --- |
| `title` | `String` | Header | First convertible value wins |
| `artist` | `String` | Header | First convertible value wins |
| `key` | `Chord` when supplied as a typed directive | Header | First typed value wins |
| `capo` | `int` or parseable integer text | Header | First convertible value wins |
| `comment` | `String` | Body | Preserved in order |

Unknown directive names can be stored in `Metadata.misc` when represented as directive lines. The current decoder does not yet emit dedicated `unknownDirective` or `invalidDirectiveValue` diagnostics.

The source editor inserts header directives in this order: `title`, `artist`, `key`, `capo`. Requesting an existing header directive selects its current value instead of adding a duplicate.

The immutable map `Interval.lookup` converts capo values from 0 through 12 into canonical intervals for chord transposition. It does not edit the directive itself. Fret 6 uses an augmented fourth, and keys outside the supported octave return `null`.

## Inline chords

Inline chords use square brackets inside lyric text:

```text
[C]Amazing [G7]grace
```

During decoding, markers are removed from the lyric text and stored as chord anchors. Each anchor offset is measured against the accumulated Dart string length of the marker-free lyric line.

### Chord syntax

```text
root[extension][/bass]
```

- `root` is required and uses an uppercase letter from `A` through `G`.
- A root may have one `#` or lowercase `b` accidental.
- `extension` is optional and preserved as uninterpreted text up to `/`.
- `/bass` is optional and follows the same note syntax as the root.
- Double accidentals and Unicode accidentals are not supported.

Examples accepted by the chord codec:

```text
C
F#7
Bbm/F
Ebmaj7/Bb
```

The chord codec requires the entire string to match. Invalid input throws `FormatException` when the codec is used directly.

## Error recovery

The song decoder reports recoverable problems in `Song.issues`:

| Code | Current trigger | Recovery |
| --- | --- | --- |
| `malformedDirective` | Invalid directive-like braces | Preserve the line as lyric text |
| `malformedChord` | Unexpected `]` or an unclosed `[` | Preserve malformed text |
| `invalidChord` | Empty marker or chord rejected by `ChordCodec` | Preserve the complete marker as lyric text |

Every issue includes a zero-based document offset plus one-based line and column positions. Consumers can render the partial song and highlight the original source simultaneously.

`unknownDirective` and `invalidDirectiveValue` are reserved issue codes; the current decoder does not produce them.

## Canonical encoding

Encoding a `Song` is normalized rather than source-preserving:

- Directive names use their normalized lowercase value.
- Directive spacing becomes `{name}` or `{name: value}`.
- Chord anchors are inserted into lyric text in the supplied order.
- Invalid anchor offsets are clamped to the remaining lyric range.
- Lines are separated with LF.
- `Song.issues` are omitted.

Use `SourceEditor` for toolbar actions that must preserve unrelated source formatting. Use `songCodec.encode` when canonical output from the parsed model is intended.

## Storage boundaries

The ChordPro parser does not know whether source text came from the local
library, an imported external file, or an in-memory editor draft. Persistence
code stores complete source strings and leaves ChordPro validation to the codec
and UI flow.

Atril's local repository writes songs with the canonical `.cho` extension.
Other accepted ChordPro-compatible extensions are read/imported but are not the
canonical extension for newly saved local songs.
