import 'dart:async';

import 'package:exceptions/src/data/error_message.dart';
import 'package:exceptions/src/data/result_exception.dart';
import 'package:fast_equatable/fast_equatable.dart';

/// A typedef for a function that handles exceptions and their stack trace.
/// It may return an [ErrorMessage] or null.
typedef ExceptionHandler = ErrorMessage? Function(
    Exception exception, StackTrace stackTrace);

// A class representing the result of an operation that can either succeed or fail.
class Result<T> with FastEquatable {
  final dynamic _value;

  /// An error message in case the result represents a failure.
  final ErrorMessage? error;

  /// A getter that returns true if the operation was successful (i.e., no error).
  bool get success => error == null;

  /// A getter that returns the value.
  /// In cases of an unsuccessuful operation, this might throw a [Exception] depending if the generic type is nullable.
  T get value => _value;

  /// A getter that returns the value if the operation was successful, or null if it wasn't.
  T? get valueOrNull => (success) ? _value : null;

  /// A getter that returns the value if the operation was successful, or throws a [ResultException] if it wasn't.
  T get valueOrException => (success) ? _value : throw ResultException(error!);

  /// Constructor for creating a [Result] instance representing a failure.
  Result.error(ErrorMessage this.error) : _value = null;

  /// Constructor for creating a [Result] instance representing a success.
  Result.value(T this._value) : error = null;

  /// A factory constructor to create a [Result] instance from a function that might throw an exception.
  factory Result.from(T Function() getter,
      {ExceptionHandler? exceptionHandler, String? errorGroup}) {
    assert(
        (exceptionHandler == null && errorGroup == null) ||
            (exceptionHandler != null) ^ (errorGroup != null),
        'Exception handler and errorgroup are mutally exclusive');

    try {
      return Result.value(getter());
    } on Exception catch (e, s) {
      return Result.error(exceptionHandler?.call(e, s) ??
          ErrorMessage.fromException(e, s, source: errorGroup));
    } catch (e) {
      return Result.error(ErrorMessage(
          message: "Unknown error", source: errorGroup, details: e));
    }
  }

  /// A static method to create a [Result] instance from an async function that might throw an exception.
  static Future<Result<T>> fromAsync<T>(Future<T> Function() getter,
      {ExceptionHandler? exceptionHandler, String? errorGroup}) async {
    assert(
        (exceptionHandler == null && errorGroup == null) ||
            (exceptionHandler != null) ^ (errorGroup != null),
        'Exception handler and errorgroup are mutally exclusive');

    try {
      return Result.value(await getter());
    } on Exception catch (e, s) {
      return Result.error(exceptionHandler?.call(e, s) ??
          ErrorMessage.fromException(e, s, source: errorGroup));
    } catch (e) {
      return Result.error(ErrorMessage(
          message: "Unknown error", source: errorGroup, details: e));
    }
  }

  @override
  bool get cacheHash => true;

  @override
  List<Object?> get hashParameters => [_value, error];
}

/// Extension on [Result] to provide additional functionalities.
extension ResultExtensions<T> on Result<T> {
  /// Maps a [Result<T>] to [Result<R>] using the provided function. If the original result is a failure, the same error is retained.
  Result<R> map<R>(R Function(T value) onSuccess,
      {ExceptionHandler? exceptionHandler, String? errorGroup}) {
    if (!success) {
      return Result.error(error!);
    }

    return Result.from(() => onSuccess(value),
        exceptionHandler: exceptionHandler, errorGroup: errorGroup);
  }

  /// Similar to [map], but for asynchronous operations. Maps a [Result<T>] to [FutureOr<Result<R>>].
  FutureOr<Result<R>> mapAsync<R>(Future<R> Function(T value) onSuccess,
      {ExceptionHandler? exceptionHandler, String? errorGroup}) {
    if (!success) {
      return Result.error(error!);
    }

    return Result.fromAsync(() => onSuccess(value),
        exceptionHandler: exceptionHandler, errorGroup: errorGroup);
  }

  /// Allows handling the success and error cases of a [Result] separately.
  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(ErrorMessage errorMessage) onError,
  }) {
    if (success) {
      return onSuccess(value);
    } else {
      return onError(error!);
    }
  }
}
