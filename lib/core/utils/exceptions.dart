/// Base type for expected domain/application failures surfaced to callers.
final class AtrilException implements Exception {
  const AtrilException(this.message);

  /// Human-readable failure reason.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Raised when user-provided input fails application validation.
final class ValidationException extends AtrilException {
  const ValidationException(super.message);
}

/// Raised when a musical transposition cannot be represented by Atril's
/// supported note spellings.
final class TranspositionException extends AtrilException {
  const TranspositionException(super.message);
}
