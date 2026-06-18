import 'dart:io';

/// Filesystem adapter used by repositories.
///
/// Paths are relative to the adapter's configured base directory. Implementors
/// own path resolution and platform-specific filesystem behavior.
abstract final class PersistenceService {
  /// Creates a directory and any missing parents.
  Future<Directory> createDirectory(String path);

  /// Lists the direct children of an existing directory.
  Future<List<FileSystemEntity>> listDirectory(String path);

  /// Returns a readable file handle for an existing file.
  Future<File> readFile(String path);

  /// Writes [content] to a file, creating missing parent directories.
  Future<File> writeFile(String path, String content);

  /// Deletes a file if it exists.
  Future<void> deleteFile(String path);
}

/// Local filesystem implementation rooted at [baseDirPath].
final class LocalPersistenceService implements PersistenceService {
  LocalPersistenceService({required this.baseDirPath});

  /// Absolute platform directory used as the root for all relative paths.
  final String baseDirPath;

  @override
  Future<Directory> createDirectory(String path) async {
    final dir = Directory(_fullDirectoryPath(path));
    return await dir.create(recursive: true);
  }

  @override
  Future<List<FileSystemEntity>> listDirectory(String path) async {
    final dir = Directory(_fullDirectoryPath(path));
    if (!await dir.exists()) {
      throw FileSystemException('Directory not found.', path);
    }

    return dir.listSync();
  }

  @override
  Future<File> readFile(String path) async {
    final file = File(_fullDirectoryPath(path));
    if (!await file.exists()) {
      throw FileSystemException('File not found.', path);
    }

    return file;
  }

  @override
  Future<File> writeFile(String path, String content) async {
    final file = File(_fullDirectoryPath(path));
    await file.create(recursive: true);

    return await file.writeAsString(content);
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(_fullDirectoryPath(path));
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _fullDirectoryPath(String path) => '$baseDirPath${Platform.pathSeparator}$path';
}
