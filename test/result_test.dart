import 'package:exceptions/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('constructor', () {
    test('with error', () {
      const error = ErrorMessage(source: 't', message: 'm');
      final result = Result.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.error, equals(error));
      expect(result.valueOrNull, isNull);
      expect(() => result.value, throwsA(isA<ResultException>()));
    });

    test('with error non-null type', () {
      const error = ErrorMessage(source: 't', message: 'm');
      final result = Result<int>.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.error, equals(error));
      expect(result.valueOrNull, isNull);
      expect(() => result.value, throwsA(isA<ResultException>()));
    });

    test('with value', () {
      final result = Result.success(1);

      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.value, equals(1));
      expect(result.valueOrNull, equals(1));
    });
  });

  group('factory', () {
    test('from with value', () {
      final result = Result.from(() => 1);
      expect(result.value, equals(1));
    });

    test('from with error', () {
      final result = Result.from(() => throw Exception());
      expect(result.isSuccess, isFalse);
    });

    test('from with error handler', () {
      final result = Result.from(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) =>
            const ErrorMessage(source: 'source', message: 'handled'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error!.message, 'handled');
    });

    test('from with error handler but unhandled', () {
      final result = Result.from(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) => null,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error!.details, isException);
    });

    test('from with error group', () {
      final result = Result.from(
        () => throw Exception(),
        errorGroup: '1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error!.source, equals('1'));
    });
  });

  group('async factory', () {
    test('from with value', () async {
      final result = await Result.fromAsync(
        () async => Future.delayed(const Duration(seconds: 1)).then((_) => 1),
      );
      expect(result.value, equals(1));
    });

    test('from with error', () async {
      final result = await Result.fromAsync(() => throw Exception());
      expect(result.isSuccess, isFalse);
    });

    test('from with error handler', () async {
      final result = await Result.fromAsync(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) =>
            const ErrorMessage(source: 'source', message: 'handled'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error!.message, 'handled');
    });

    test('from with error handler but unhandled', () async {
      final result = await Result.fromAsync(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) => null,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error!.details, isException);
    });

    test('from with error group', () async {
      final result = await Result.fromAsync(
        () => throw Exception(),
        errorGroup: '1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error!.source, equals('1'));
    });
  });
}
