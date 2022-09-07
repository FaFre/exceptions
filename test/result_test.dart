import 'package:exceptions/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('constructor', () {
    test('with error', () {
      final error = ErrorMessage(source: 't', message: 'm');
      final result = Result.error(error);

      expect(result.success, isFalse);
      expect(result.error, equals(error));
      expect(result.value, isNull);
      expect(result.valueOrNull, isNull);
      expect(() => result.valueOrException, throwsA(isA<ResultException>()));
    });

    test('with error non-null type', () {
      final error = ErrorMessage(source: 't', message: 'm');
      final result = Result<int>.error(error);

      expect(result.success, isFalse);
      expect(result.error, equals(error));
      expect(() => result.value, throwsA(isA<TypeError>()));
      expect(result.valueOrNull, isNull);
      expect(() => result.valueOrException, throwsA(isA<ResultException>()));
    });

    test('with value', () {
      final result = Result.value(1);

      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.value, equals(1));
      expect(result.valueOrNull, equals(1));
      expect(result.valueOrException, equals(1));
    });
  });

  group('factory', () {
    test('from with value', () {
      final result = Result.from(() => 1);
      expect(result.value, equals(1));
    });

    test('from with error', () {
      final result = Result.from(() => throw Exception());
      expect(result.success, isFalse);
    });

    test('from with error handler', () {
      final result = Result.from(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) =>
            ErrorMessage(source: 'source', message: 'handled'),
      );

      expect(result.success, isFalse);
      expect(result.error!.message, 'handled');
    });

    test('from with error handler but unhandled', () {
      final result = Result.from(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) => null,
      );

      expect(result.success, isFalse);
      expect(result.error!.details, isException);
    });

    test('from with error group', () {
      final result = Result.from(
        () => throw Exception(),
        errorGroup: '1',
      );

      expect(result.success, isFalse);
      expect(result.error!.source, equals('1'));
    });
  });

  group('async factory', () {
    test('from with value', () async {
      final result = await Result.fromAsync(() async =>
          Future.delayed(const Duration(seconds: 1)).then((_) => 1));
      expect(result.value, equals(1));
    });

    test('from with error', () async {
      final result = await Result.fromAsync(() => throw Exception());
      expect(result.success, isFalse);
    });

    test('from with error handler', () async {
      final result = await Result.fromAsync(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) =>
            ErrorMessage(source: 'source', message: 'handled'),
      );

      expect(result.success, isFalse);
      expect(result.error!.message, 'handled');
    });

    test('from with error handler but unhandled', () async {
      final result = await Result.fromAsync(
        () => throw Exception(),
        exceptionHandler: (exception, stackTrace) => null,
      );

      expect(result.success, isFalse);
      expect(result.error!.details, isException);
    });

    test('from with error group', () async {
      final result = await Result.fromAsync(
        () => throw Exception(),
        errorGroup: '1',
      );

      expect(result.success, isFalse);
      expect(result.error!.source, equals('1'));
    });
  });
}
