import 'package:atril/domain/models/song/source_location.dart';

/// Stable categories of problems found while decoding song source.
enum ParseIssueCode { malformedDirective, unknownDirective, invalidDirectiveValue, malformedChord, invalidChord }

extension ParseIssueCodeExtension on ParseIssueCode {
  String get message => switch (this) {
    ParseIssueCode.malformedDirective => 'Malformed directive',
    ParseIssueCode.unknownDirective => 'Unknown directive',
    ParseIssueCode.invalidDirectiveValue => 'Invalid directive value',
    ParseIssueCode.malformedChord => 'Malformed chord',
    ParseIssueCode.invalidChord => 'Invalid chord',
  };
}

/// The impact of a [ParseIssue] on parsing or later operations.
enum ParseIssueSeverity { warning, error, fatal }

/// A non-throwing diagnostic produced while parsing recoverable source.
///
/// The decoder keeps malformed text in the song model where possible and adds
/// an issue describing the original source span. This lets an editor render a
/// partial preview and highlight validation errors at the same time.
final class ParseIssue({
  /// The machine-readable category of the problem.
  required final ParseIssueCode code,

  /// The diagnostic severity.
  required final ParseIssueSeverity severity,

  /// A human-readable description suitable for editor feedback.
  required final String message,

  /// The source span that caused the issue.
  required final SourceLocation location,
});
