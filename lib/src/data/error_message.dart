class ErrorMessage {
  final String? source;
  final String message;

  final dynamic details;
  final StackTrace? stackTrace;

  const ErrorMessage({
    required this.source,
    required this.message,
    this.details,
    this.stackTrace,
  });

  ErrorMessage.fromException(
    Exception e,
    StackTrace? s, {
    String? source,
    dynamic details,
  }) : this(
          source: source,
          message: e.toString(),
          details: details ?? e,
          stackTrace: s,
        );

  @override
  int get hashCode => Object.hash(source, message, details);

  @override
  String toString() {
    return message;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ErrorMessage) return false;

    return source == other.source &&
        message == other.message &&
        details == other.details;
  }
}
