import 'package:fast_equatable/fast_equatable.dart';

class ErrorMessage with FastEquatable {
  final String? source;
  final String message;

  final dynamic details;
  final StackTrace? stackTrace;

  ErrorMessage(
      {required this.source,
      required this.message,
      this.details,
      this.stackTrace});

  factory ErrorMessage.fromException(Exception e, StackTrace? s,
          {String? source, dynamic details}) =>
      ErrorMessage(
          source: source,
          message: e.toString(),
          details: details ?? e,
          stackTrace: s);

  @override
  bool get cacheHash => true;

  @override
  List<Object?> get hashParameters => [source, message, details];

  @override
  String toString() {
    return message;
  }
}
