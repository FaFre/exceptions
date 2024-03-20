import 'dart:async';

import 'package:exceptions/src/data/error_message.dart';
import 'package:exceptions/src/data/result_exception.dart';

/// A typedef for a function that handles exceptions and their stack trace.
/// It may return an [ErrorMessage] or null.
typedef ExceptionHandler = ErrorMessage? Function(
  Exception exception,
  StackTrace stackTrace,
);

/// A class representing the result of an operation that can either succeed or fail.
sealed class Result<T> {
  const Result();

  /// A getter that returns true if the operation was successful (i.e., no error).
  bool get isSuccess;

  /// An error message in case the result represents a failure.
  ErrorMessage? get error;

  /// A getter that returns the value if the operation was successful, or throws a [ResultException] if it wasn't.
  T get value;

  /// A getter that returns the value if the operation was successful, or null if it wasn't.
  T? get valueOrNull;

  /// Factory for creating a [Result] instance representing a failure.
  factory Result.failure(ErrorMessage error) => Failure<T>(error);

  /// Factory for creating a [Result] instance representing a success.
  factory Result.success(T value) => Success<T>(value);

  /// A factory constructor to create a [Result] instance from a function that might throw an exception.
  /// The [ExceptionHandler] can be provided to handle exceptions and return an [ErrorMessage].
  /// The [errorGroup] can be used to categorize the type of error.
  factory Result.from(
    T Function() getter, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) {
    assert(
      (exceptionHandler == null && errorGroup == null) ||
          (exceptionHandler != null) ^ (errorGroup != null),
      'Exception handler and error group are mutually exclusive',
    );

    try {
      return Result.success(getter());
    } on Exception catch (e, s) {
      return Result.failure(
        exceptionHandler?.call(e, s) ??
            ErrorMessage.fromException(e, s, source: errorGroup),
      );
    } catch (e) {
      return Result.failure(
        ErrorMessage(
          message: "Unknown error",
          source: errorGroup,
          details: e,
        ),
      );
    }
  }

  /// A static method to create a [Result] instance from an async function that might throw an exception.
  /// The [ExceptionHandler] can be provided to handle exceptions and return an [ErrorMessage].
  /// The [errorGroup] can be used to categorize the type of error.
  static Future<Result<T>> fromAsync<T>(
    Future<T> Function() getter, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) async {
    assert(
      (exceptionHandler == null && errorGroup == null) ||
          (exceptionHandler != null) ^ (errorGroup != null),
      'Exception handler and error group are mutually exclusive',
    );

    try {
      return Result.success(await getter());
    } on Exception catch (e, s) {
      return Result.failure(
        exceptionHandler?.call(e, s) ??
            ErrorMessage.fromException(e, s, source: errorGroup),
      );
    } catch (e) {
      return Result.failure(
        ErrorMessage(
          message: "Unknown error",
          source: errorGroup,
          details: e,
        ),
      );
    }
  }

  /// Allows handling the success and failure cases of a [Result] separately and returns a value of type [R].
  ///
  /// [onSuccess] is the function that transforms the value if the result is a success.
  /// [onFailure] is the function that transforms the error message if the result is a failure.
  R fold<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage errorMessage) onFailure,
  });

  /// Similar to [fold], but ensures that the value is not null before calling [onSuccess].
  ///
  /// [onSuccess] is the function that transforms the value if the result is a success and not null.
  /// [onNullOrFailure] is the function that transforms the error message or provides a default value if the result is null or a failure.
  R? foldNotNull<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage errorMessage) onFailure,
  });

  /// Calls the provided callback if the result is a success.
  ///
  /// [callback] is the function to be called with the value if the result is a success.
  void onSuccess(void Function(T value) callback);

  /// Calls the provided callback if the result is a failure.
  ///
  /// [callback] is the function to be called with the error message if the result is a failure.
  void onFailure(void Function(ErrorMessage errorMessage) callback);

  /// Calls the appropriate callback based on the result being a success or a failure.
  ///
  /// [onSuccess] is the function to be called with the value if the result is a success.
  /// [onFailure] is the function to be called with the error message if the result is a failure.
  void map({
    required void Function(T value) onSuccess,
    required void Function(ErrorMessage errorMessage) onFailure,
  });

  /// Recovers from a failure by providing a new value.
  ///
  /// [onRecover] is the function that provides a new value in case the result is a failure.
  Success<T> recover(T Function(ErrorMessage errorMessage) onRecover);

  /// Maps a [Result<T>] to [Result<R>] using the provided function. If the original result is a failure, the same error is retained.
  ///
  /// [onSuccess] is the function that transforms the value if the result is a success.
  /// [exceptionHandler] is an optional handler for any exceptions thrown during the transformation.
  /// [errorGroup] is an optional group identifier for the error.
  Result<R> flatMap<R>(
    R Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  });

  /// Similar to [flatMap], but for asynchronous operations. Maps a [Result<T>] to [FutureOr<Result<R>>].
  ///
  /// [onSuccess] is the function that asynchronously transforms the value if the result is a success.
  /// [exceptionHandler] is an optional handler for any exceptions thrown during the transformation.
  /// [errorGroup] is an optional group identifier for the error.
  FutureOr<Result<R>> flatMapAsync<R>(
    Future<R> Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  });

  @override
  String toString() => fold(
        (value) => value.toString(),
        onFailure: (errorMessage) => errorMessage.toString(),
      );
}

final class Success<T> extends Result<T> {
  final T _value;

  const Success(this._value);

  @override
  bool get isSuccess => true;

  @override
  T get value => _value;

  @override
  T get valueOrNull => _value;

  @override
  ErrorMessage? get error => null;

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Success<T>) return false;

    return _value == other._value;
  }

  @override
  R fold<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage errorMessage) onFailure,
  }) =>
      onSuccess(_value);

  @override
  R? foldNotNull<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage errorMessage) onFailure,
  }) =>
      (_value != null) ? onSuccess(_value) : null;

  @override
  void onSuccess(void Function(T value) callback) => callback.call(_value);

  @override
  void onFailure(void Function(ErrorMessage errorMessage) callback) {}

  @override
  void map({
    required void Function(T value) onSuccess,
    required void Function(ErrorMessage errorMessage) onFailure,
  }) =>
      onSuccess.call(_value);

  @override
  Success<T> recover(T Function(ErrorMessage errorMessage) onRecover) => this;

  @override
  Result<R> flatMap<R>(
    R Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) =>
      Result.from(
        () => onSuccess(_value),
        exceptionHandler: exceptionHandler,
        errorGroup: errorGroup,
      );

  @override
  FutureOr<Result<R>> flatMapAsync<R>(
    Future<R> Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) =>
      Result.fromAsync(
        () => onSuccess(_value),
        exceptionHandler: exceptionHandler,
        errorGroup: errorGroup,
      );
}

final class Failure<T> extends Result<T> {
  final ErrorMessage _error;

  const Failure(this._error);

  @override
  bool get isSuccess => false;

  @override
  T get value => throw ResultException(_error);

  @override
  T? get valueOrNull => null;

  @override
  ErrorMessage get error => _error;

  @override
  int get hashCode => _error.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Failure<T>) return false;

    return _error == other._error;
  }

  @override
  R fold<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage errorMessage) onFailure,
  }) =>
      onFailure(_error);

  @override
  R? foldNotNull<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage errorMessage) onFailure,
  }) =>
      onFailure(_error);

  @override
  void onSuccess(void Function(T value) callback) {}

  @override
  void onFailure(void Function(ErrorMessage errorMessage) callback) =>
      callback.call(_error);

  @override
  void map({
    required void Function(T value) onSuccess,
    required void Function(ErrorMessage errorMessage) onFailure,
  }) =>
      onFailure.call(_error);

  @override
  Success<T> recover(T Function(ErrorMessage errorMessage) onRecover) =>
      Success(onRecover(error));

  @override
  Failure<R> flatMap<R>(
    R Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) =>
      Failure(_error);

  @override
  FutureOr<Failure<R>> flatMapAsync<R>(
    Future<R> Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) =>
      Failure<R>(error);
}
