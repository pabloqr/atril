/// Explicit success-or-failure result for repository and service operations.
///
/// Use [Result] at application boundaries where failures are expected and the
/// caller should decide how to present them. Unexpected programming errors can
/// still throw normally.
///
/// The result can be evaluated using a switch statement:
/// ```dart
/// switch (result) {
///   case Ok(): {
///     print(result.value);
///   }
///   case Error(): {
///     print(result.error);
///   }
/// }
/// ```
sealed class const Result<T>() {
  /// Creates a successful [Result], completed with the specified [value].
  const factory ok(T value) = Ok._;

  /// Creates an error [Result], completed with the specified [error].
  const factory error(Exception error) = Error._;
}

/// Successful operation result.
final class const Ok<T>._(
  /// Returned operation value.
  final T value,
) extends Result<T> {
  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// Failed operation result.
final class const Error<T>._(
  /// Error captured from the operation.
  final Exception error,
) extends Result<T> {
  @override
  String toString() => 'Result<$T>.error($error)';
}
