import 'exceptions.dart';
import 'value.dart';

/// Converts an arbitrary Dart value to a [SilhouetteValue].
///
/// Supports conversion of:
/// - `null` -> [SilhouetteNull]
/// - [String] -> [SilhouetteString]
/// - [bool] -> [SilhouetteBool]
/// - [int] -> [SilhouetteInt]
/// - [double] -> [SilhouetteDouble]
/// - [List] -> [SilhouetteList] (with recursive conversion of elements)
/// - [Set] -> [SilhouetteSet] (with recursive conversion of elements)
/// - [Map] -> [SilhouetteMap] or [SilhouetteObject] based on key type
/// - [SilhouetteValue] -> returned as-is
///
/// Throws [SilhouetteException] if the value type is not supported.
///
/// Example:
/// ```dart
/// final value = toSilhouetteValue('hello'); // SilhouetteString('hello')
/// final nested = toSilhouetteValue([1, 2, 3]); // SilhouetteList([...])
/// final obj = toSilhouetteValue({'name': 'John'}); // SilhouetteObject({...})
/// ```
SilhouetteValue _toSilhouetteValue(Object? value) => switch (value) {
  null => SilhouetteNull(),
  String() => value.toSilhouette,
  bool() => value.toSilhouette,
  int() => value.toSilhouette,
  double() => value.toSilhouette,
  List<Object?>() => value.toSilhouette,
  Set<Object?>() => value.toSilhouette,
  Map<Object?, Object?>() => value.toSilhouette,
  SilhouetteValue() => value,
  _ => throw SilhouetteException(
    'Can\'t convert ${value.runtimeType} to SilhouetteValue.',
  ),
};

/// Extension to convert [String] values to [SilhouetteString].
extension SilhouetteStringConversion on String {
  /// Converts this string to a [SilhouetteString].
  ///
  /// Example:
  /// ```dart
  /// final silhouetteStr = 'hello'.toSilhouette;
  /// ```
  SilhouetteString get toSilhouette => SilhouetteString(this);
}

/// Extension to convert [bool] values to [SilhouetteBool].
extension SilhouetteBoolConversion on bool {
  /// Converts this boolean to a [SilhouetteBool].
  ///
  /// Example:
  /// ```dart
  /// final silhouetteBool = true.toSilhouette;
  /// ```
  SilhouetteBool get toSilhouette => SilhouetteBool(this);
}

/// Extension to convert [int] values to [SilhouetteInt].
extension SilhouetteIntConversion on int {
  /// Converts this integer to a [SilhouetteInt].
  ///
  /// Example:
  /// ```dart
  /// final silhouetteInt = 42.toSilhouette;
  /// ```
  SilhouetteInt get toSilhouette => SilhouetteInt(this);
}

/// Extension to convert [double] values to [SilhouetteDouble].
extension SilhouetteDoubleConversion on double {
  /// Converts this double to a [SilhouetteDouble].
  ///
  /// Example:
  /// ```dart
  /// final silhouetteDouble = 3.14.toSilhouette;
  /// ```
  SilhouetteDouble get toSilhouette => SilhouetteDouble(this);
}

/// Extension to convert [List] values to [SilhouetteList].
extension SilhouetteListConversion<T> on List<T> {
  /// Converts this list to a [SilhouetteList] and
  /// each of its elements to a corresponding [SilhouetteValue].
  ///
  /// If its elements can't be converted to [SilhouetteValue],
  /// throws a [SilhouetteException].
  ///
  /// Example:
  /// ```dart
  /// final list = ['a', 'b', 'c'].toSilhouette;
  ///
  /// final nested = [1, [2, 3]].toSilhouette;
  /// ```
  SilhouetteList<SilhouetteValue> get toSilhouette {
    return SilhouetteList(
      map(_toSilhouetteValue).toList(),
    );
  }
}

/// Extension to convert [Set] values to [SilhouetteSet].
extension SilhouetteSetConversion<T> on Set<T> {
  /// Converts this set to a [SilhouetteSet] and
  /// each of its elements to a corresponding [SilhouetteValue].
  ///
  /// If its elements can't be converted to a [SilhouetteValue] that
  /// implements [SilhouetteEquatable], throws a [SilhouetteException].
  ///
  /// Example:
  /// ```dart
  /// final set = {'a', 'b', 'c'}.toSilhouette;
  /// ```
  SilhouetteSet<SilhouetteEquatable> get toSilhouette {
    return SilhouetteSet(
      map(_toSilhouetteValue).map((e) => e as SilhouetteEquatable).toSet(),
    );
  }
}

/// Extension to convert [Map] values to [SilhouetteMap].
extension SilhouetteMapConversion<K, V> on Map<K, V> {
  /// Converts this map to a [SilhouetteMap] and
  /// each of its keys and values to a corresponding [SilhouetteValue].
  ///
  /// If its keys can't be converted to a [SilhouetteValue] that
  /// implements [SilhouetteEquatable], throws a [SilhouetteException].
  ///
  /// If its values can't be converted to [SilhouetteValue],
  /// throws a [SilhouetteException].
  ///
  /// Example:
  /// ```dart
  /// final map = {1: 'one', 2: 'two'}.toSilhouette;
  /// ```
  SilhouetteMap<SilhouetteEquatable, SilhouetteValue> get toSilhouette {
    final convertedMap = <SilhouetteEquatable, SilhouetteValue>{};
    for (final entry in entries) {
      final convertedKey = _toSilhouetteValue(entry.key);
      if (convertedKey is! SilhouetteEquatable) {
        throw SilhouetteException(
          'Map keys must be equatable, found ${convertedKey.runtimeType}',
        );
      }
      convertedMap[convertedKey] = _toSilhouetteValue(entry.value);
    }
    return SilhouetteMap(convertedMap);
  }
}

/// Extension to convert [Map] values with string keys to [SilhouetteObject].
extension SilhouetteObjectConversion<V> on Map<String, V> {
  /// Converts this map to a [SilhouetteObject] and
  /// each of its values to a corresponding [SilhouetteValue].
  ///
  /// If its keys aren't valid Silhouette identifiers,
  /// throws a [SilhouetteException].
  ///
  /// If its values can't be converted to a [SilhouetteValue],
  /// throws a [SilhouetteException].
  ///
  ///
  /// Example:
  /// ```dart
  /// final obj = {'name': 'John', 'age': 30}.toSilhouetteObject;
  /// ```
  SilhouetteObject get toSilhouetteObject {
    return SilhouetteObject({
      for (final MapEntry(:key, :value) in entries)
        SilhouetteIdentifier(key): _toSilhouetteValue(value),
    });
  }
}
