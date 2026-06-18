# Atril

Atril is an Android-first Flutter application for editing, previewing, transposing, and locally saving song chord sheets in ChordPro text format.

## Features

- Local song library with create, rename, delete, title/artist search, selectable title/artist sorting, and distinct empty/no-match states.
- A new library is initialized once with `Amazing Grace`; deleting every song does not recreate it.
- ChordPro source editor with a fixed monospace editing field, immediate parsed preview, and validation feedback.
- Quick editor actions for `{title: ...}`, `{artist: ...}`, `{key: ...}`, `{capo: ...}`, and repeatable `{comment: ...}` directives without rewriting unaffected source text.
- Ordered song preview with chords above lyric text, `{comment: ...}` section headings, and one shared horizontal scroll area for long lines.
- Transposition controls for previewing another key without changing source, plus an explicit apply action that writes the displayed key into editable ChordPro text without saving automatically.
- Local `.cho` persistence in the application documents directory.
- Visible names come from `{title: ...}` while stable internal file identifiers remain separate.
- Library search is local, matches saved title or artist without case/common Latin accent distinctions, and leaves unsaved editor changes out of results until saved.
- Import of `.cho`, `.crd`, `.chopro`, `.chord`, and `.pro` UTF-8 documents as unsaved drafts; an import reaches the local library only after an explicit valid save.
- External export has repository and picker contracts, but the implementation is still pending.
- Pure Dart parser, serializer, chord transposer, source transposer, and source-preserving directive editor with test coverage.

Atril currently implements a deliberately small ChordPro subset. See [docs/chordpro_subset.md](docs/chordpro_subset.md) for supported directives and syntax, [docs/architecture.md](docs/architecture.md) for source and persistence boundaries, and [docs/persistence.md](docs/persistence.md) for local/external file contracts.

## Development Checks

```bash
dart format lib test
flutter analyze
flutter test
```
