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
class Result<T> {
  final dynamic _value;

  /// An error message in case the result represents a failure.
  final ErrorMessage? error;

  /// A getter that returns true if the operation was successful (i.e., no error).
  bool get isSuccess => error == null;

  /// A getter that returns the value if the operation was successful.
  /// If the operation was unsuccessful and the generic type is non-nullable, accessing this getter will throw an [Exception].
  T get value => _value as T;

  /// A getter that returns the value if the operation was successful, or null if it wasn't.
  T? get valueOrNull => isSuccess ? _value as T : null;

  /// A getter that returns the value if the operation was successful, or throws a [ResultException] if it wasn't.
  T get valueOrException =>
      isSuccess ? _value as T : throw ResultException(error!);

  /// Converts the Result to a Future that completes with the current Result instance.
  Future<Result<T>> toFuture() async {
    return this;
  }

  /// Constructor for creating a [Result] instance representing a failure.
  const Result.failure(ErrorMessage this.error) : _value = null;

  /// Constructor for creating a [Result] instance representing a success.
  const Result.success(T this._value) : error = null;

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

  @override
  int get hashCode => Object.hash(_value, error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Result<T>) return false;

    return _value == other._value && error == other.error;
  }

  @override
  String toString() => fold(
        (value) => value.toString(),
        onFailure: (errorMessage) => errorMessage.toString(),
      );
}

/// Extension on [Result] to provide additional functionalities.
extension ResultExtensions<T> on Result<T> {
  /// Maps a [Result<T>] to [Result<R>] using the provided function. If the original result is a failure, the same error is retained.
  ///
  /// [onSuccess] is the function that transforms the value if the result is a success.
  /// [exceptionHandler] is an optional handler for any exceptions thrown during the transformation.
  /// [errorGroup] is an optional group identifier for the error.
  Result<R> flatMap<R>(
    R Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) =>
      isSuccess
          ? Result.from(
              () => onSuccess(value),
              exceptionHandler: exceptionHandler,
              errorGroup: errorGroup,
            )
          : Result.failure(error!);

  /// Similar to [flatMap], but for asynchronous operations. Maps a [Result<T>] to [FutureOr<Result<R>>].
  ///
  /// [onSuccess] is the function that asynchronously transforms the value if the result is a success.
  /// [exceptionHandler] is an optional handler for any exceptions thrown during the transformation.
  /// [errorGroup] is an optional group identifier for the error.
  FutureOr<Result<R>> flatMapAsync<R>(
    Future<R> Function(T value) onSuccess, {
    ExceptionHandler? exceptionHandler,
    String? errorGroup,
  }) =>
      isSuccess
          ? Result.fromAsync(
              () => onSuccess(value),
              exceptionHandler: exceptionHandler,
              errorGroup: errorGroup,
            )
          : Result<R>.failure(error!).toFuture();

  /// Calls the provided callback if the result is a success.
  ///
  /// [callback] is the function to be called with the value if the result is a success.
  void onSuccess(void Function(T value) callback) {
    if (isSuccess) callback(value);
  }

  /// Calls the provided callback if the result is a failure.
  ///
  /// [callback] is the function to be called with the error message if the result is a failure.
  void onFailure(void Function(ErrorMessage errorMessage) callback) {
    if (!isSuccess) callback(error!);
  }

  /// Recovers from a failure by providing a new value.
  ///
  /// [onRecover] is the function that provides a new value in case the result is a failure.
  Result<T> recover(T Function(ErrorMessage errorMessage) onRecover) {
    return isSuccess ? this : Result.success(onRecover(error!));
  }

  /// Calls the appropriate callback based on the result being a success or a failure.
  ///
  /// [onSuccess] is the function to be called with the value if the result is a success.
  /// [onFailure] is the function to be called with the error message if the result is a failure.
  void map({
    required void Function(T value) onSuccess,
    required void Function(ErrorMessage errorMessage) onFailure,
  }) {
    if (isSuccess) {
      onSuccess(value);
    } else {
      onFailure(error!);
    }
  }

  /// Allows handling the success and failure cases of a [Result] separately and returns a value of type [R].
  ///
  /// [onSuccess] is the function that transforms the value if the result is a success.
  /// [onFailure] is the function that transforms the error message if the result is a failure.
  R fold<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage errorMessage) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(value);
    } else {
      return onFailure(error!);
    }
  }

  /// Similar to [fold], but ensures that the value is not null before calling [onSuccess].
  ///
  /// [onSuccess] is the function that transforms the value if the result is a success and not null.
  /// [onNullOrFailure] is the function that transforms the error message or provides a default value if the result is null or a failure.
  R foldNotNull<R>(
    R Function(T value) onSuccess, {
    required R Function(ErrorMessage? errorMessage) onNullOrFailure,
  }) {
    if (isSuccess && value != null) {
      return onSuccess(value);
    } else {
      return onNullOrFailure(error);
    }
  }
}
