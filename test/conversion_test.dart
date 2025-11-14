import 'package:silhouette/silhouette.dart';
import 'package:test/test.dart';

void main() {
  group('SilhouetteStringConversion', () {
    test('converts string using toSilhouette getter', () {
      final result = 'hello world'.toSilhouette;
      expect(result, isA<SilhouetteString>());
      expect(result.value, equals('hello world'));
      expect(result.toString(), equals('hello world'));
    });

    test('converts empty string', () {
      final result = ''.toSilhouette;
      expect(result.value, equals(''));
    });

    test('converts string with special characters', () {
      final result = 'Hello\n\tWorld!'.toSilhouette;
      expect(result.value, equals('Hello\n\tWorld!'));
    });
  });

  group('SilhouetteBoolConversion', () {
    test('converts true using toSilhouette getter', () {
      final result = true.toSilhouette;
      expect(result, isA<SilhouetteBool>());
      expect(result.value, isTrue);
      expect(result.toString(), equals('true'));
    });

    test('converts false using toSilhouette getter', () {
      final result = false.toSilhouette;
      expect(result.value, isFalse);
      expect(result.toString(), equals('false'));
    });
  });

  group('SilhouetteIntConversion', () {
    test('converts positive integer using toSilhouette getter', () {
      final result = 42.toSilhouette;
      expect(result, isA<SilhouetteInt>());
      expect(result.value, equals(42));
      expect(result.toString(), equals('42'));
    });

    test('converts zero', () {
      final result = 0.toSilhouette;
      expect(result.value, equals(0));
    });

    test('converts negative integer', () {
      final result = (-123).toSilhouette;
      expect(result.value, equals(-123));
    });
  });

  group('SilhouetteDoubleConversion', () {
    test('converts positive double using toSilhouette getter', () {
      final result = 3.14.toSilhouette;
      expect(result, isA<SilhouetteDouble>());
      expect(result.value, equals(3.14));
    });

    test('converts negative double', () {
      final result = (-2.5).toSilhouette;
      expect(result.value, equals(-2.5));
    });

    test('converts zero as double', () {
      final result = 0.0.toSilhouette;
      expect(result.value, equals(0.0));
    });
  });

  group('SilhouetteListConversion', () {
    test('converts list of strings', () {
      final result = ['a', 'b', 'c'].toSilhouette;
      expect(result, isA<SilhouetteList>());
      expect(result.value.length, equals(3));
      expect(result.value[0], isA<SilhouetteString>());
      expect((result.value[0] as SilhouetteString).value, equals('a'));
    });

    test('converts list of integers', () {
      final result = [1, 2, 3].toSilhouette;
      expect(result.value.length, equals(3));
      expect(result.value[0], isA<SilhouetteInt>());
      expect((result.value[0] as SilhouetteInt).value, equals(1));
    });

    test('converts list of mixed types', () {
      final result = ['text', 42, true, 3.14].toSilhouette;
      expect(result.value.length, equals(4));
      expect(result.value[0], isA<SilhouetteString>());
      expect(result.value[1], isA<SilhouetteInt>());
      expect(result.value[2], isA<SilhouetteBool>());
      expect(result.value[3], isA<SilhouetteDouble>());
    });

    test('converts empty list', () {
      final result = <int>[].toSilhouette;
      expect(result.value.isEmpty, isTrue);
    });

    test('converts nested lists', () {
      final result = [
        1,
        [2, 3],
        [
          [4, 5],
        ],
      ].toSilhouette;
      expect(result.value.length, equals(3));
      expect(result.value[0], isA<SilhouetteInt>());
      expect(result.value[1], isA<SilhouetteList>());
      expect(result.value[2], isA<SilhouetteList>());

      final nested = result.value[1] as SilhouetteList;
      expect(nested.value.length, equals(2));
      expect((nested.value[0] as SilhouetteInt).value, equals(2));
    });

    test('converts list with null values', () {
      final result = [1, null, 3].toSilhouette;
      expect(result.value.length, equals(3));
      expect(result.value[1], isA<SilhouetteNull>());
    });
  });

  group('SilhouetteSetConversion', () {
    test('converts set of strings', () {
      final result = {'a', 'b', 'c'}.toSilhouette;
      expect(result, isA<SilhouetteSet>());
      expect(result.value.length, equals(3));
      expect(result.value.first, isA<SilhouetteString>());
    });

    test('converts set of integers', () {
      final result = {1, 2, 3}.toSilhouette;
      expect(result.value.length, equals(3));
      expect(result.value.first, isA<SilhouetteInt>());
    });

    test('converts empty set', () {
      final result = <String>{}.toSilhouette;
      expect(result.value.isEmpty, isTrue);
    });

    test('throws for non-equatable elements', () {
      expect(
        () => {DateTime.now()}.toSilhouette,
        throwsA(isA<SilhouetteException>()),
      );
    });
  });

  group('SilhouetteMapConversion - toSilhouette', () {
    test('converts map with string keys', () {
      final result = {'name': 'John', 'age': 30}.toSilhouette;
      expect(result, isA<SilhouetteMap>());
    });

    test('converts map with int keys', () {
      final result = {1: 'one', 2: 'two'}.toSilhouette;
      expect(result, isA<SilhouetteMap>());
    });

    test('handles nested maps', () {
      final result = {
        'user': {'name': 'John', 'age': 30},
        'admin': true,
      }.toSilhouette;

      expect(result, isA<SilhouetteMap>());
      final user = result.value[const SilhouetteString('user')];
      expect(user, isA<SilhouetteMap>());
    });
  });

  group('SilhouetteObjectConversion - toSilhouetteObject', () {
    test('converts map with valid identifier keys', () {
      final result = {
        'name': 'John',
        'age': 30,
        'is_admin': true,
      }.toSilhouetteObject;
      expect(result, isA<SilhouetteObject>());
      expect(result.value.length, equals(3));

      final name = result.value[SilhouetteIdentifier('name')];
      expect(name, isA<SilhouetteString>());
      expect((name as SilhouetteString).value, equals('John'));

      final age = result.value[SilhouetteIdentifier('age')];
      expect(age, isA<SilhouetteInt>());
      expect((age as SilhouetteInt).value, equals(30));
    });

    test('throws for invalid identifier keys', () {
      expect(
        () => {'invalid-name': 'value'}.toSilhouetteObject,
        throwsA(isA<SilhouetteException>()),
      );
    });

    test('throws for keys starting with digit', () {
      expect(
        () => {'123invalid': 'value'}.toSilhouetteObject,
        throwsA(isA<SilhouetteException>()),
      );
    });

    test('accepts underscores in keys', () {
      final result = {
        'valid_name': 'value',
        '_private': 'data',
      }.toSilhouetteObject;
      expect(result.value.length, equals(2));
    });

    test('converts nested maps in objects', () {
      final result = {
        'user': {
          'name': 'John',
          'address': {
            'city': 'NYC',
            'zip': 10001,
          },
        },
      }.toSilhouetteObject;

      expect(result, isA<SilhouetteObject>());
      final user = result.value[SilhouetteIdentifier('user')];
      expect(user, isA<SilhouetteMap>());

      final userMap = user as SilhouetteMap;
      final address = userMap.value[const SilhouetteString('address')];
      expect(address, isA<SilhouetteMap>());
    });
  });

  group('Complex nested conversions', () {
    test('converts list of maps', () {
      final data = [
        {'id': 1, 'name': 'Item 1'},
        {'id': 2, 'name': 'Item 2'},
      ];

      final result = data.toSilhouette;
      expect(result, isA<SilhouetteList>());
      expect(result.value.length, equals(2));
      expect(result.value[0], isA<SilhouetteMap>());
    });

    test('converts map with list values', () {
      final data = {
        'numbers': [1, 2, 3],
        'words': ['a', 'b', 'c'],
        'mixed': [1, 'two', true],
      };

      final result = data.toSilhouette;
      final numbers = result.value[const SilhouetteString('numbers')];
      expect(numbers, isA<SilhouetteList>());
      expect((numbers as SilhouetteList).value.length, equals(3));
    });
  });

  group('Edge cases', () {
    test('handles very large numbers', () {
      final largeInt = 9223372036854775807.toSilhouette; // Max int64
      expect(largeInt.value, equals(9223372036854775807));

      final largeDouble =
          1.7976931348623157e+308.toSilhouette; // Near max double
      expect(largeDouble.value, equals(1.7976931348623157e+308));
    });

    test('handles very small numbers', () {
      final smallDouble = 2.2250738585072014e-308.toSilhouette;
      expect(smallDouble.value, equals(2.2250738585072014e-308));
    });

    test('handles special double values', () {
      final nan = double.nan.toSilhouette;
      expect(nan.value.isNaN, isTrue);

      final infinity = double.infinity.toSilhouette;
      expect(infinity.value.isInfinite, isTrue);

      final negInfinity = double.negativeInfinity.toSilhouette;
      expect(negInfinity.value, equals(double.negativeInfinity));
    });

    test('handles unicode strings', () {
      final emoji = '👋 Hello 🌍'.toSilhouette;
      expect(emoji.value, equals('👋 Hello 🌍'));

      final chinese = '你好世界'.toSilhouette;
      expect(chinese.value, equals('你好世界'));
    });

    test('handles empty collections', () {
      final emptyList = <int>[].toSilhouette;
      expect(emptyList.value.isEmpty, isTrue);

      final emptySet = <int>{}.toSilhouette;
      expect(emptySet.value.isEmpty, isTrue);

      final emptyMap = <String, int>{}.toSilhouette;
      expect(emptyMap, isA<SilhouetteMap>());

      final emptyObject = <String, int>{}.toSilhouetteObject;
      expect(emptyObject, isA<SilhouetteObject>());
    });
  });
}
