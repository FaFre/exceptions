import 'dart:async';

import 'package:exceptions/src/data/error_message.dart';
import 'package:exceptions/src/data/result_exception.dart';
import 'package:fast_equatable/fast_equatable.dart';

typedef ExceptionHandler = ErrorMessage? Function(
    Exception exception, StackTrace stackTrace);

class Result<T> with FastEquatable {
  final dynamic _value;

  final ErrorMessage? error;
  bool get success => error == null;

  T get value => _value;
  T? get valueOrNull => (success) ? _value : null;
  T get valueOrException => (success) ? _value : throw ResultException(error!);

  Result.error(ErrorMessage this.error) : _value = null;

  Result.value(T this._value) : error = null;

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

extension ResulExtensions<T> on Result<T> {
  Result<R> map<R>(R Function(T? value) onSuccess,
      {ExceptionHandler? exceptionHandler, String? errorGroup}) {
    if (!success) {
      return Result.error(error!);
    }

    return Result.from(() => onSuccess(value),
        exceptionHandler: exceptionHandler, errorGroup: errorGroup);
  }

  FutureOr<Result<R>> mapAsync<R>(Future<R> Function(T? value) onSuccess,
      {ExceptionHandler? exceptionHandler, String? errorGroup}) {
    if (!success) {
      return Result.error(error!);
    }

    return Result.fromAsync(() => onSuccess(value),
        exceptionHandler: exceptionHandler, errorGroup: errorGroup);
  }
}
