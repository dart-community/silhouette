import 'package:silhouette/silhouette.dart';
import 'package:test/test.dart';

void main() {
  group('SilhouetteNull', () {
    test('is a singleton', () {
      final null1 = SilhouetteNull();
      final null2 = SilhouetteNull();
      expect(identical(null1, null2), isTrue);
    });

    test('equality works correctly', () {
      final null1 = SilhouetteNull();
      final null2 = SilhouetteNull();
      expect(null1 == null2, isTrue);
      expect(null1.hashCode, equals(0));
    });

    test('toString returns "null"', () {
      expect(SilhouetteNull().toString(), equals('null'));
    });

    test('retrieve throws exception', () {
      expect(
        () async => await SilhouetteNull().retrieve(
          SilhouetteIdentifier('anything'),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SilhouetteString', () {
    test('stores and returns string value', () {
      const value = SilhouetteString('hello');
      expect(value.value, equals('hello'));
      expect(value.toString(), equals('hello'));
    });

    test('equality and hashCode work correctly', () {
      const str1 = SilhouetteString('test');
      const str2 = SilhouetteString('test');
      const str3 = SilhouetteString('different');

      expect(str1 == str2, isTrue);
      expect(str1 == str3, isFalse);
      expect(str1.hashCode, equals(str2.hashCode));
      expect(str1.hashCode, isNot(equals(str3.hashCode)));
    });

    group('string properties', () {
      const testString = SilhouetteString('Hello World');

      test('toUpperCase property', () async {
        final result = await testString.retrieve(
          SilhouetteIdentifier('toUpperCase'),
        );
        expect(result, isA<SilhouetteString>());
        expect((result as SilhouetteString).value, equals('HELLO WORLD'));
      });

      test('toLowerCase property', () async {
        final result = await testString.retrieve(
          SilhouetteIdentifier('toLowerCase'),
        );
        expect(result, isA<SilhouetteString>());
        expect((result as SilhouetteString).value, equals('hello world'));
      });

      test('isEmpty property', () async {
        const empty = SilhouetteString('');
        const notEmpty = SilhouetteString('test');

        final emptyResult = await empty.retrieve(
          SilhouetteIdentifier('isEmpty'),
        );
        final notEmptyResult = await notEmpty.retrieve(
          SilhouetteIdentifier('isEmpty'),
        );

        expect(emptyResult, isA<SilhouetteBool>());
        expect((emptyResult as SilhouetteBool).value, isTrue);
        expect((notEmptyResult as SilhouetteBool).value, isFalse);
      });

      test('isNotEmpty property', () async {
        const empty = SilhouetteString('');
        const notEmpty = SilhouetteString('test');

        final emptyResult = await empty.retrieve(
          SilhouetteIdentifier('isNotEmpty'),
        );
        final notEmptyResult = await notEmpty.retrieve(
          SilhouetteIdentifier('isNotEmpty'),
        );

        expect((emptyResult as SilhouetteBool).value, isFalse);
        expect((notEmptyResult as SilhouetteBool).value, isTrue);
      });

      test('length property', () async {
        final result = await testString.retrieve(
          SilhouetteIdentifier('length'),
        );
        expect(result, isA<SilhouetteInt>());
        expect((result as SilhouetteInt).value, equals(11));
      });
    });

    group('string methods', () {
      const testString = SilhouetteString('Hello World');

      test('substring method', () async {
        final substringFunc = await testString.retrieve(
          SilhouetteIdentifier('substring'),
        );
        expect(substringFunc, isA<SilhouetteFunction>());

        final func = substringFunc as SilhouetteFunction;

        // Test substring with start only.
        final args1 = SilhouetteArguments(
          positional: [const SilhouetteInt(6)],
          named: {},
        );
        final result1 = await func.call(args1);
        expect(result1, isA<SilhouetteString>());
        expect((result1 as SilhouetteString).value, equals('World'));

        // Test substring with start and end.
        final args2 = SilhouetteArguments(
          positional: [const SilhouetteInt(0)],
          named: {SilhouetteIdentifier('end'): const SilhouetteInt(5)},
        );
        final result2 = await func.call(args2);
        expect((result2 as SilhouetteString).value, equals('Hello'));
      });

      test('replace method', () async {
        final replaceFunc = await testString.retrieve(
          SilhouetteIdentifier('replace'),
        );
        expect(replaceFunc, isA<SilhouetteFunction>());

        final func = replaceFunc as SilhouetteFunction;
        final args = SilhouetteArguments(
          positional: [
            const SilhouetteString('World'),
            const SilhouetteString('Dart'),
          ],
          named: {},
        );
        final result = await func.call(args);
        expect((result as SilhouetteString).value, equals('Hello Dart'));
      });

      test('contains method', () async {
        final containsFunc = await testString.retrieve(
          SilhouetteIdentifier('contains'),
        );
        final func = containsFunc as SilhouetteFunction;

        final args1 = SilhouetteArguments(
          positional: [const SilhouetteString('World')],
          named: {},
        );
        final result1 = await func.call(args1);
        expect((result1 as SilhouetteBool).value, isTrue);

        final args2 = SilhouetteArguments(
          positional: [const SilhouetteString('xyz')],
          named: {},
        );
        final result2 = await func.call(args2);
        expect((result2 as SilhouetteBool).value, isFalse);
      });

      test('startsWith method', () async {
        final startsWithFunc = await testString.retrieve(
          SilhouetteIdentifier('startsWith'),
        );
        final func = startsWithFunc as SilhouetteFunction;

        final args1 = SilhouetteArguments(
          positional: [const SilhouetteString('Hello')],
          named: {},
        );
        final result1 = await func.call(args1);
        expect((result1 as SilhouetteBool).value, isTrue);

        final args2 = SilhouetteArguments(
          positional: [const SilhouetteString('World')],
          named: {},
        );
        final result2 = await func.call(args2);
        expect((result2 as SilhouetteBool).value, isFalse);
      });

      test('endsWith method', () async {
        final endsWithFunc = await testString.retrieve(
          SilhouetteIdentifier('endsWith'),
        );
        final func = endsWithFunc as SilhouetteFunction;

        final args1 = SilhouetteArguments(
          positional: [const SilhouetteString('World')],
          named: {},
        );
        final result1 = await func.call(args1);
        expect((result1 as SilhouetteBool).value, isTrue);

        final args2 = SilhouetteArguments(
          positional: [const SilhouetteString('Hello')],
          named: {},
        );
        final result2 = await func.call(args2);
        expect((result2 as SilhouetteBool).value, isFalse);
      });

      test('split method', () async {
        final splitFunc = await testString.retrieve(
          SilhouetteIdentifier('split'),
        );
        final func = splitFunc as SilhouetteFunction;

        final args = SilhouetteArguments(
          positional: [const SilhouetteString(' ')],
          named: {},
        );
        final result = await func.call(args);
        expect(result, isA<SilhouetteList>());

        final list = result as SilhouetteList;
        expect(list.value.length, equals(2));
        expect((list.value[0] as SilhouetteString).value, equals('Hello'));
        expect((list.value[1] as SilhouetteString).value, equals('World'));
      });

      test('trim method', () async {
        const stringWithSpaces = SilhouetteString('  test  ');
        final trimFunc = await stringWithSpaces.retrieve(
          SilhouetteIdentifier('trim'),
        );
        final func = trimFunc as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = await func.call(args);
        expect((result as SilhouetteString).value, equals('test'));
      });
    });

    test('unknown property throws exception', () {
      const str = SilhouetteString('test');
      expect(
        () async => await str.retrieve(
          SilhouetteIdentifier('unknownProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteBool', () {
    test('stores and returns boolean value', () {
      const trueValue = SilhouetteBool(true);
      const falseValue = SilhouetteBool(false);

      expect(trueValue.value, isTrue);
      expect(falseValue.value, isFalse);
      expect(trueValue.toString(), equals('true'));
      expect(falseValue.toString(), equals('false'));
    });

    test('equality and hashCode work correctly', () {
      const bool1 = SilhouetteBool(true);
      const bool2 = SilhouetteBool(true);
      const bool3 = SilhouetteBool(false);

      expect(bool1 == bool2, isTrue);
      expect(bool1 == bool3, isFalse);
      expect(bool1.hashCode, equals(bool2.hashCode));
      expect(bool1.hashCode, isNot(equals(bool3.hashCode)));
    });

    test('retrieve throws exception for any property', () {
      const boolValue = SilhouetteBool(true);
      expect(
        () async => await boolValue.retrieve(
          SilhouetteIdentifier('anyProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteInt', () {
    test('stores and returns integer value', () {
      const intValue = SilhouetteInt(42);
      expect(intValue.value, equals(42));
      expect(intValue.toString(), equals('42'));
    });

    test('equality and hashCode work correctly', () {
      const int1 = SilhouetteInt(42);
      const int2 = SilhouetteInt(42);
      const int3 = SilhouetteInt(24);

      expect(int1 == int2, isTrue);
      expect(int1 == int3, isFalse);
      expect(int1.hashCode, equals(int2.hashCode));
      expect(int1.hashCode, isNot(equals(int3.hashCode)));
    });

    test('isEven property works correctly', () async {
      const evenInt = SilhouetteInt(4);
      const oddInt = SilhouetteInt(5);

      final evenResult = await evenInt.retrieve(
        SilhouetteIdentifier('isEven'),
      );
      final oddResult = await oddInt.retrieve(
        SilhouetteIdentifier('isEven'),
      );

      expect((evenResult as SilhouetteBool).value, isTrue);
      expect((oddResult as SilhouetteBool).value, isFalse);
    });

    test('isOdd property works correctly', () async {
      const evenInt = SilhouetteInt(4);
      const oddInt = SilhouetteInt(5);

      final evenResult = await evenInt.retrieve(
        SilhouetteIdentifier('isOdd'),
      );
      final oddResult = await oddInt.retrieve(
        SilhouetteIdentifier('isOdd'),
      );

      expect((evenResult as SilhouetteBool).value, isFalse);
      expect((oddResult as SilhouetteBool).value, isTrue);
    });

    group('numeric methods', () {
      test('abs method with positive integer', () async {
        const intValue = SilhouetteInt(42);
        final absFunc =
            (await intValue.retrieve(
                  SilhouetteIdentifier('abs'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = (await absFunc.call(args)) as SilhouetteInt;

        expect(result.value, equals(42));
      });

      test('abs method with negative integer', () async {
        const intValue = SilhouetteInt(-42);
        final absFunc =
            (await intValue.retrieve(
                  SilhouetteIdentifier('abs'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = (await absFunc.call(args)) as SilhouetteInt;

        expect(result.value, equals(42));
      });

      test('toStringAsFixed method', () async {
        const intValue = SilhouetteInt(42);
        final toStringAsFixedFunc =
            (await intValue.retrieve(
                  SilhouetteIdentifier('toStringAsFixed'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(
          positional: [const SilhouetteInt(2)],
          named: {},
        );
        final result =
            (await toStringAsFixedFunc.call(args)) as SilhouetteString;

        expect(result.value, equals('42.00'));
      });

      test('toStringAsFixed method throws with no arguments', () async {
        const intValue = SilhouetteInt(42);
        final toStringAsFixedFunc =
            (await intValue.retrieve(
                  SilhouetteIdentifier('toStringAsFixed'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});

        expect(
          () async => await toStringAsFixedFunc.call(args),
          throwsA(isA<SilhouetteException>()),
        );
      });

      test('toStringAsFixed method throws with wrong argument type', () async {
        const intValue = SilhouetteInt(42);
        final toStringAsFixedFunc =
            (await intValue.retrieve(
                  SilhouetteIdentifier('toStringAsFixed'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(
          positional: [const SilhouetteString('invalid')],
          named: {},
        );

        expect(
          () async => await toStringAsFixedFunc.call(args),
          throwsA(isA<SilhouetteException>()),
        );
      });
    });

    test('unknown property throws exception', () {
      const intValue = SilhouetteInt(42);
      expect(
        () async => await intValue.retrieve(
          SilhouetteIdentifier('unknownProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteDouble', () {
    test('stores and returns double value', () {
      const doubleValue = SilhouetteDouble(3.14);
      expect(doubleValue.value, equals(3.14));
      expect(doubleValue.toString(), equals('3.14'));
    });

    test('equality and hashCode work correctly', () {
      const double1 = SilhouetteDouble(3.14);
      const double2 = SilhouetteDouble(3.14);
      const double3 = SilhouetteDouble(2.71);

      expect(double1 == double2, isTrue);
      expect(double1 == double3, isFalse);
      expect(double1.hashCode, equals(double2.hashCode));
      expect(double1.hashCode, isNot(equals(double3.hashCode)));
    });

    group('numeric methods', () {
      test('abs method with positive double', () async {
        const doubleValue = SilhouetteDouble(3.14);
        final absFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('abs'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = (await absFunc.call(args)) as SilhouetteDouble;

        expect(result.value, equals(3.14));
      });

      test('abs method with negative double', () async {
        const doubleValue = SilhouetteDouble(-3.14);
        final absFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('abs'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = (await absFunc.call(args)) as SilhouetteDouble;

        expect(result.value, equals(3.14));
      });

      test('round method', () async {
        const doubleValue = SilhouetteDouble(3.7);
        final roundFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('round'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = (await roundFunc.call(args)) as SilhouetteInt;

        expect(result.value, equals(4));
      });

      test('floor method', () async {
        const doubleValue = SilhouetteDouble(3.9);
        final floorFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('floor'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = (await floorFunc.call(args)) as SilhouetteInt;

        expect(result.value, equals(3));
      });

      test('ceil method', () async {
        const doubleValue = SilhouetteDouble(3.1);
        final ceilFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('ceil'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = (await ceilFunc.call(args)) as SilhouetteInt;

        expect(result.value, equals(4));
      });

      test('toStringAsFixed method', () async {
        const doubleValue = SilhouetteDouble(3.14159);
        final toStringAsFixedFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('toStringAsFixed'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(
          positional: [const SilhouetteInt(2)],
          named: {},
        );
        final result =
            (await toStringAsFixedFunc.call(args)) as SilhouetteString;

        expect(result.value, equals('3.14'));
      });

      test('toStringAsFixed method throws with no arguments', () async {
        const doubleValue = SilhouetteDouble(3.14);
        final toStringAsFixedFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('toStringAsFixed'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});

        expect(
          () async => await toStringAsFixedFunc.call(args),
          throwsA(isA<SilhouetteException>()),
        );
      });

      test('toStringAsFixed method throws with wrong argument type', () async {
        const doubleValue = SilhouetteDouble(3.14);
        final toStringAsFixedFunc =
            (await doubleValue.retrieve(
                  SilhouetteIdentifier('toStringAsFixed'),
                ))
                as SilhouetteFunction;

        final args = SilhouetteArguments(
          positional: [const SilhouetteString('invalid')],
          named: {},
        );

        expect(
          () async => await toStringAsFixedFunc.call(args),
          throwsA(isA<SilhouetteException>()),
        );
      });
    });

    test('retrieve throws exception for any property', () {
      const doubleValue = SilhouetteDouble(3.14);
      expect(
        () async => await doubleValue.retrieve(
          SilhouetteIdentifier('anyProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteNumber', () {
    test('int and double have same base behavior but are not equal', () {
      const intValue = SilhouetteInt(42);
      const doubleValue = SilhouetteDouble(42.0);

      // They have the same value but are different types
      expect(intValue.value, equals(doubleValue.value));
      expect(intValue == doubleValue, isFalse);
      expect(intValue.hashCode, equals(doubleValue.hashCode));
    });
  });

  group('SilhouetteList', () {
    const testList = SilhouetteList<SilhouetteString>([
      SilhouetteString('first'),
      SilhouetteString('second'),
      SilhouetteString('third'),
    ]);

    test('stores and accesses list elements', () {
      expect(testList.value.length, equals(3));
      expect(testList.toString(), contains('first'));
    });

    test('forKey works correctly', () {
      final first = testList.forKey(const SilhouetteInt(0));
      final second = testList.forKey(const SilhouetteInt(1));

      expect(first.value, equals('first'));
      expect(second.value, equals('second'));
    });

    test('forKey throws for invalid index', () {
      expect(
        () => testList.forKey(const SilhouetteInt(-1)),
        throwsA(isA<UnknownKeyException>()),
      );
      expect(
        () => testList.forKey(const SilhouetteInt(10)),
        throwsA(isA<UnknownKeyException>()),
      );
    });

    group('list properties', () {
      test('length property', () async {
        final result = await testList.retrieve(
          SilhouetteIdentifier('length'),
        );
        expect((result as SilhouetteInt).value, equals(3));
      });

      test('isEmpty property', () async {
        const empty = SilhouetteList(<SilhouetteValue>[]);
        final emptyResult = await empty.retrieve(
          SilhouetteIdentifier('isEmpty'),
        );
        final notEmptyResult = await testList.retrieve(
          SilhouetteIdentifier('isEmpty'),
        );

        expect((emptyResult as SilhouetteBool).value, isTrue);
        expect((notEmptyResult as SilhouetteBool).value, isFalse);
      });

      test('isNotEmpty property', () async {
        const empty = SilhouetteList(<SilhouetteValue>[]);
        final emptyResult = await empty.retrieve(
          SilhouetteIdentifier('isNotEmpty'),
        );
        final notEmptyResult = await testList.retrieve(
          SilhouetteIdentifier('isNotEmpty'),
        );

        expect((emptyResult as SilhouetteBool).value, isFalse);
        expect((notEmptyResult as SilhouetteBool).value, isTrue);
      });

      test('first property', () async {
        final result = await testList.retrieve(
          SilhouetteIdentifier('first'),
        );
        expect((result as SilhouetteString).value, equals('first'));
      });

      test('first property throws on empty list', () {
        const empty = SilhouetteList(<SilhouetteValue>[]);
        expect(
          () async => await empty.retrieve(
            SilhouetteIdentifier('first'),
          ),
          throwsA(isA<SilhouetteException>()),
        );
      });

      test('last property', () async {
        final result = await testList.retrieve(
          SilhouetteIdentifier('last'),
        );
        expect((result as SilhouetteString).value, equals('third'));
      });

      test('last property throws on empty list', () {
        const empty = SilhouetteList(<SilhouetteValue>[]);
        expect(
          () async => await empty.retrieve(
            SilhouetteIdentifier('last'),
          ),
          throwsA(isA<SilhouetteException>()),
        );
      });
    });

    group('list methods', () {
      test('join method', () async {
        final joinFunc = await testList.retrieve(
          SilhouetteIdentifier('join'),
        );
        final func = joinFunc as SilhouetteFunction;

        final args = SilhouetteArguments(
          positional: [const SilhouetteString(', ')],
          named: {},
        );
        final result = await func.call(args);
        expect(
          (result as SilhouetteString).value,
          equals('first, second, third'),
        );
      });

      test('reverse method', () async {
        final reverseFunc = await testList.retrieve(
          SilhouetteIdentifier('reverse'),
        );
        final func = reverseFunc as SilhouetteFunction;

        final args = SilhouetteArguments(positional: [], named: {});
        final result = await func.call(args);
        final reversed = result as SilhouetteList;

        expect((reversed.value[0] as SilhouetteString).value, equals('third'));
        expect((reversed.value[1] as SilhouetteString).value, equals('second'));
        expect((reversed.value[2] as SilhouetteString).value, equals('first'));
      });

      test('contains method', () async {
        final containsFunc = await testList.retrieve(
          SilhouetteIdentifier('contains'),
        );
        final func = containsFunc as SilhouetteFunction;

        final args1 = SilhouetteArguments(
          positional: [const SilhouetteString('first')],
          named: {},
        );
        final result1 = await func.call(args1);
        expect((result1 as SilhouetteBool).value, isTrue);

        final args2 = SilhouetteArguments(
          positional: [const SilhouetteString('notfound')],
          named: {},
        );
        final result2 = await func.call(args2);
        expect((result2 as SilhouetteBool).value, isFalse);
      });

      test('slice method', () async {
        final sliceFunc = await testList.retrieve(
          SilhouetteIdentifier('slice'),
        );
        final func = sliceFunc as SilhouetteFunction;

        // Test slice with start only.
        final args1 = SilhouetteArguments(
          positional: [],
          named: {SilhouetteIdentifier('start'): const SilhouetteInt(1)},
        );
        final result1 = await func.call(args1);
        final sliced1 = result1 as SilhouetteList;
        expect(sliced1.value.length, equals(2));
        expect((sliced1.value[0] as SilhouetteString).value, equals('second'));

        // Test slice with start and end.
        final args2 = SilhouetteArguments(
          positional: [],
          named: {
            SilhouetteIdentifier('start'): const SilhouetteInt(0),
            SilhouetteIdentifier('end'): const SilhouetteInt(2),
          },
        );
        final result2 = await func.call(args2);
        final sliced2 = result2 as SilhouetteList;
        expect(sliced2.value.length, equals(2));
        expect((sliced2.value[0] as SilhouetteString).value, equals('first'));
        expect((sliced2.value[1] as SilhouetteString).value, equals('second'));
      });
    });

    test('unknown property throws exception', () {
      expect(
        () async => await testList.retrieve(
          SilhouetteIdentifier('unknownProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteSet', () {
    final testSet = SilhouetteSet({
      const SilhouetteString('a'),
      const SilhouetteString('b'),
      const SilhouetteString('c'),
    });

    test('stores set and provides properties', () {
      expect(testSet.value.length, equals(3));
      expect(testSet.toString(), contains('a'));
    });

    test('length property', () async {
      final result = await testSet.retrieve(
        SilhouetteIdentifier('length'),
      );
      expect((result as SilhouetteInt).value, equals(3));
    });

    test('isEmpty and isNotEmpty properties', () async {
      const empty = SilhouetteSet(<SilhouetteString>{});

      final emptyResult = await empty.retrieve(
        SilhouetteIdentifier('isEmpty'),
      );
      final notEmptyResult = await testSet.retrieve(
        SilhouetteIdentifier('isEmpty'),
      );

      expect((emptyResult as SilhouetteBool).value, isTrue);
      expect((notEmptyResult as SilhouetteBool).value, isFalse);

      final emptyNotEmptyResult = await empty.retrieve(
        SilhouetteIdentifier('isNotEmpty'),
      );
      final notEmptyNotEmptyResult = await testSet.retrieve(
        SilhouetteIdentifier('isNotEmpty'),
      );

      expect((emptyNotEmptyResult as SilhouetteBool).value, isFalse);
      expect((notEmptyNotEmptyResult as SilhouetteBool).value, isTrue);
    });

    test('unknown property throws exception', () {
      expect(
        () async => await testSet.retrieve(
          SilhouetteIdentifier('unknownProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteMap', () {
    final testMap = SilhouetteMap<SilhouetteString, SilhouetteString>({
      const SilhouetteString('key1'): const SilhouetteString('value1'),
      const SilhouetteString('key2'): const SilhouetteString('value2'),
    });

    test('stores map and provides access', () {
      expect(testMap.value.length, equals(2));
      expect(testMap.toString(), contains('key1'));
    });

    test('forKey works correctly', () {
      final value1 = testMap.forKey(const SilhouetteString('key1'));
      expect(value1.value, equals('value1'));
    });

    test('forKey throws for unknown key', () {
      expect(
        () => testMap.forKey(const SilhouetteString('unknownKey')),
        throwsA(isA<UnknownKeyException>()),
      );
    });

    group('map properties', () {
      test('length property', () async {
        final result = await testMap.retrieve(
          SilhouetteIdentifier('length'),
        );
        expect((result as SilhouetteInt).value, equals(2));
      });

      test('isEmpty and isNotEmpty properties', () async {
        const empty = SilhouetteMap(<SilhouetteString, SilhouetteValue>{});

        final emptyResult = await empty.retrieve(
          SilhouetteIdentifier('isEmpty'),
        );
        final notEmptyResult = await testMap.retrieve(
          SilhouetteIdentifier('isEmpty'),
        );

        expect((emptyResult as SilhouetteBool).value, isTrue);
        expect((notEmptyResult as SilhouetteBool).value, isFalse);
      });

      test('keys property', () async {
        final result = await testMap.retrieve(
          SilhouetteIdentifier('keys'),
        );
        expect(result, isA<SilhouetteSet>());
        final keys = result as SilhouetteSet;
        expect(keys.value.contains(const SilhouetteString('key1')), isTrue);
        expect(keys.value.contains(const SilhouetteString('key2')), isTrue);
      });

      test('values property', () async {
        final result = await testMap.retrieve(
          SilhouetteIdentifier('values'),
        );
        expect(result, isA<SilhouetteList>());
        final values = result as SilhouetteList;
        expect(values.value.length, equals(2));
      });
    });

    test('unknown property throws exception', () {
      expect(
        () async => await testMap.retrieve(
          SilhouetteIdentifier('unknownProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteObject', () {
    final testData = SilhouetteObject({
      SilhouetteIdentifier('name'): const SilhouetteString('John'),
      SilhouetteIdentifier('age'): const SilhouetteInt(30),
    });

    test('stores data and provides access', () {
      expect(testData.value.length, equals(2));
      expect(testData.toString(), contains('name'));
    });

    test('retrieve works correctly', () async {
      final name = await testData.retrieve(
        SilhouetteIdentifier('name'),
      );
      final age = await testData.retrieve(
        SilhouetteIdentifier('age'),
      );

      expect((name as SilhouetteString).value, equals('John'));
      expect((age as SilhouetteInt).value, equals(30));
    });

    test('forKey works correctly', () {
      final name = testData.forKey(const SilhouetteString('name'));
      expect((name as SilhouetteString).value, equals('John'));
    });

    test('retrieve throws for unknown property', () {
      expect(
        () => testData.retrieve(SilhouetteIdentifier('unknownProperty')),
        throwsA(isA<UnknownPropertyException>()),
      );
    });

    test('forKey throws for unknown key', () {
      expect(
        () => testData.forKey(const SilhouetteString('unknownKey')),
        throwsA(isA<UnknownPropertyException>()),
      );
    });
  });

  group('SilhouetteFunction', () {
    test('stores and calls function correctly', () async {
      final func = SilhouetteFunction((args) {
        final first = args.positional.isNotEmpty ? args.positional[0] : null;
        if (first is SilhouetteInt) {
          return SilhouetteInt(first.value * 2);
        }
        return SilhouetteNull();
      });

      final args = SilhouetteArguments(
        positional: [const SilhouetteInt(5)],
        named: {},
      );
      final result = await func.call(args);
      expect((result as SilhouetteInt).value, equals(10));
    });

    test('retrieve throws exception for any property', () {
      final func = SilhouetteFunction((args) => SilhouetteNull());
      expect(
        () async => await func.retrieve(
          SilhouetteIdentifier('anyProperty'),
        ),
        throwsA(isA<UnknownPropertyException>()),
      );
    });

    test('toString passes through underlying function', () {
      final func = SilhouetteFunction((args) => SilhouetteNull());
      expect(
        func.toString(),
        equals('Closure: (SilhouetteArguments) => SilhouetteNull'),
      );
    });
  });

  group('SilhouetteArguments', () {
    test('stores positional and named arguments', () {
      final args = SilhouetteArguments(
        positional: [const SilhouetteString('pos1'), const SilhouetteInt(42)],
        named: {
          SilhouetteIdentifier('key1'): const SilhouetteString('named1'),
        },
      );

      expect(args.positional.length, equals(2));
      expect(args.named.length, equals(1));
      expect((args.positional[0] as SilhouetteString).value, equals('pos1'));
      expect(
        (args.named[SilhouetteIdentifier('key1')] as SilhouetteString).value,
        equals('named1'),
      );
    });
  });

  group('Exception classes', () {
    test('UnknownPropertyException toString works correctly', () async {
      try {
        const str = SilhouetteString('test');
        await str.retrieve(SilhouetteIdentifier('unknownProperty'));
      } catch (e) {
        expect(
          e.toString(),
          equals('SilhouetteException: Unknown property: unknownProperty'),
        );
      }
    });

    test('UnknownKeyException toString works correctly', () {
      try {
        const testList = SilhouetteList<SilhouetteString>([
          SilhouetteString('test'),
        ]);
        print(testList.forKey(const SilhouetteInt(5)));
      } catch (e) {
        expect(e.toString(), equals('SilhouetteException: Unknown key: 5'));
      }
    });
  });
}
