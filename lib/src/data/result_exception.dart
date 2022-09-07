import 'package:exceptions/src/data/error_message.dart';

class ResultException implements Exception {
  final ErrorMessage errorMessage;

  ResultException(this.errorMessage);
}
