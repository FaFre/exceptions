import 'package:exceptions/src/data/error_message.dart';

class ResultException implements Exception {
  final ErrorMessage errorMessage;

  const ResultException(this.errorMessage);

  @override
  String toString() => errorMessage.toString();
}
