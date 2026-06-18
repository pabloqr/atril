import 'package:atril/core/utils/result.dart';

/// Helpers for adapting [Result] APIs to call sites that still use exceptions.
class ResultUtils {
  /// Returns the success value or throws the contained error.
  static T unwrapOrThrow<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
}
