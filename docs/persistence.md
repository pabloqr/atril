# Persistence and external files

This page is the reference for Atril's current file persistence boundaries.

## Models

### `SongFile`

| Field | Type | Description |
| --- | --- | --- |
| `name` | `String` | Stable storage name without any repository-added extension. This is not necessarily the ChordPro `{title}`. |
| `source` | `String` | Complete ChordPro source text. |

## Constants

| Constant | Value | Description |
| --- | --- | --- |
| `Constants.songDirPath` | `song` | Relative local-library directory under the platform documents root. |
| `Constants.allowedFileExtensions` | `cho`, `crd`, `chopro`, `chord`, `pro` | Extensions accepted by local listing and external import. |
| `Constants.songFileExtension` | `cho` | Extension used when Atril writes local song files. |

## Local library repository

### `SongRepository.getSongs`

Returns `Result<List<SongFile>>`.

The repository lists `Constants.songDirPath`, filters files by allowed
extension, sorts paths lexicographically, reads each file, strips its extension,
and returns the resulting `SongFile` values.

The current implementation returns `Result.error` if the library directory does
not exist. Callers that want an empty first-run library must create the
directory before listing or handle that error explicitly.

### `SongRepository.saveSong`

Returns `Result<SongFile>`.

The repository accepts only names matching:

```text
^[A-Za-z0-9_-]+$
```

Invalid names return `ValidationException` inside `Result.error`. Valid names
are written below `Constants.songDirPath` with the canonical `.cho` extension.

### `SongRepository.deleteSong`

Returns `Result<void>`.

The same name validation used by `saveSong` applies. Deleting a valid missing
file is treated as success by the local persistence service.

## Filesystem service

### `PersistenceService`

| Method | Behavior |
| --- | --- |
| `createDirectory(path)` | Creates the relative directory and missing parents. |
| `listDirectory(path)` | Lists direct children of an existing relative directory. |
| `readFile(path)` | Returns a file handle for an existing relative file. |
| `writeFile(path, content)` | Creates missing parents and writes text content. |
| `deleteFile(path)` | Deletes the relative file if it exists. |

`LocalPersistenceService` resolves every path under its configured
`baseDirPath`. It is deliberately filesystem-level: repositories decide naming,
extensions, and result mapping.

## External files

### `ExternalFileRepository.importFile`

Returns `Result<SongFile?>`.

| Outcome | Result |
| --- | --- |
| User selects a valid UTF-8 file | `Ok(SongFile)` |
| User cancels selection | `Ok(null)` |
| Selection or decoding fails | `Error(exception)` |

Selected files are decoded as UTF-8 without allowing malformed byte sequences.
The imported document is an unsaved draft until another flow writes it to the
local library.

### `ExternalFileRepository.exportFile`

External export is not implemented yet. The repository method and underlying
file picker method currently throw `UnimplementedError`; callers must not expose
this as a completed feature.
