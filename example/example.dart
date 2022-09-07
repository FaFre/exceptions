import 'dart:io';

import 'package:exceptions/exceptions.dart';
import 'package:http/http.dart';

extension ExceptionHandling on Client {
  Future<Result<Response>> getGuarded(Uri url, {Map<String, String>? headers}) {
    return Result.fromAsync(
      () => get(url, headers: headers).then((response) {
        if (response.statusCode != 200) {
          throw HttpException('${response.statusCode}');
        }
        return response;
      }),
      exceptionHandler: (exception, stackTrace) {
        switch (exception.runtimeType) {
          case SocketException:
            return ErrorMessage(
                source: 'http',
                message: 'No Internet connection',
                details: url);
          case HttpException:
            return ErrorMessage(
                source: 'http',
                message: 'Web request returned error',
                details: url);
          case FormatException:
            return ErrorMessage(
                source: 'http', message: 'Bad response format', details: url);
          default:
            return null;
        }
      },
    );
  }
}
