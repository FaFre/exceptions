## Overview

This package helps catching and handling occuring `Exception`'s by producing a single `Result` that either contains an error or value. 
Very helpful to process `Exception`'s internally and provide a proper message for users.

> This package is currently in alpha state and the API is probably changing!

## Example

```dart
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

```