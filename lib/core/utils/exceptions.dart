/// Base type for expected domain/application failures surfaced to callers.
final class const AtrilException(
  /// Human-readable failure reason.
  final String message,
) implements Exception {
  @override
  String toString() => '$runtimeType: $message';
}

/// Raised when user-provided input fails application validation.
final class const ValidationException(super.message) extends AtrilException;

/// Raised when a musical transposition cannot be represented by Atril's
/// supported note spellings.
final class const TranspositionException(super.message) extends AtrilException;
