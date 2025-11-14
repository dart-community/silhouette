import 'dart:async' show FutureOr;

import 'package:meta/meta.dart';

import 'chars.dart';
import 'exceptions.dart';

/// A type-safe identifier for Silhouette template variables.
///
/// This extension type provides a lightweight wrapper around strings
/// to represent variable identifiers in template contexts.
extension type const SilhouetteIdentifier._(String identifier)
    implements String {
  /// Creates a [SilhouetteIdentifier] from the specified [identifier] string.
  ///
  /// The [identifier] should be a valid Silhouette identifier,
  /// starting with a letter or underscore, and
  /// containing only letters, digits, and underscores.
  ///
  /// Throws a [SilhouetteException] if the identifier is invalid.
  SilhouetteIdentifier(this.identifier) {
    if (!isValidIdentifier(identifier)) {
      throw SilhouetteException(
        'Invalid identifier "$identifier": must start with a letter or '
        'underscore and contain only letters, digits, and underscores',
      );
    }
  }

  /// Validates that a string is a valid Silhouette identifier.
  ///
  /// Returns `true` if the string starts with a letter or underscore
  /// and contains only letters, digits, and underscores.
  static bool isValidIdentifier(String identifier) {
    final codeUnits = identifier.codeUnits;
    if (codeUnits.isEmpty) {
      return false;
    }

    final firstChar = codeUnits[0];

    // First character must be a letter (a-z, A-Z) or underscore (_).
    if (!Chars.isAlpha(firstChar) && firstChar != Chars.underscore) {
      return false;
    }

    // Remaining characters can be letters, digits, or underscores.
    for (var i = 1; i < codeUnits.length; i++) {
      final char = codeUnits[i];
      if (!Chars.isAlphaNumeric(char) && char != Chars.underscore) {
        return false;
      }
    }

    return true;
  }
}

/// Base class for all values in the Silhouette template system.
///
/// All data that can be used in templates must extend this class. It provides
/// the foundation for property access and string conversion that templates
/// rely on for rendering and expression evaluation.
@immutable
abstract base class SilhouetteValue {
  /// Creates a new Silhouette value.
  const SilhouetteValue();

  /// Retrieves a property with the given [propertyName].
  ///
  /// This method is used for dot notation property access in templates,
  /// such as `{{ user.name }}` or `{{ text.length }}`. The implementation
  /// should return the appropriate [SilhouetteValue] for the property.
  ///
  /// Throws an exception if the property doesn't exist on this value type.
  ///
  /// Example:
  /// ```dart
  /// final user = SilhouetteObject({
  ///   SilhouetteIdentifier('name'): SilhouetteString('Dash'),
  /// });
  /// final name = user.retrieve(
  ///   SilhouetteIdentifier(('name')),
  /// ); // Returns SilhouetteString('Dash')
  /// ```
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName);

  /// Returns a string representation of this value.
  ///
  /// This method is used when values are rendered in templates or
  /// converted to strings for output. Implementations should return
  /// a human-readable representation appropriate for template rendering.
  @override
  @mustBeOverridden
  String toString();
}

/// A mixin that adds equality comparison to Silhouette values.
///
/// Values that implement this mixin can be compared for equality and
/// used as keys in maps or elements in sets. This is essential for
/// template operations like `contains()` checks and map key lookups.
///
/// Classes using this mixin must override [hashCode], [operator ==],
/// and [toString] to provide proper equality semantics.
base mixin SilhouetteEquatable on SilhouetteValue {
  /// The hash code for this value.
  ///
  /// Must be consistent with [operator ==] - objects that are equal
  /// must have the same hash code.
  @override
  @mustBeOverridden
  int get hashCode;

  /// Whether this value is equal to [other].
  ///
  /// Two values are considered equal if they are the same type and
  /// contain equivalent data. This is used for template comparisons
  /// and collection operations.
  @override
  @mustBeOverridden
  bool operator ==(Object other);

  /// Returns a string representation of this equatable value.
  ///
  /// Must be overridden to provide a meaningful string representation
  /// for debugging and template rendering purposes.
  @override
  @mustBeOverridden
  String toString() => throw UnimplementedError('You must override toString.');
}

/// A mixin that adds indexing capability to Silhouette values.
///
/// Values that implement this mixin can be accessed using bracket notation
/// in templates, such as `{{ items[0] }}` or `{{ data['key'] }}`. The key
/// type is parameterized to allow different indexing strategies.
///
/// Type parameter [Key] must extend [SilhouetteEquatable] to ensure keys can be
/// compared properly for lookups.
base mixin SilhouetteIndexable<
  Key extends SilhouetteEquatable,
  Value extends SilhouetteValue
>
    on SilhouetteValue {
  /// Retrieves the value associated with the given [key].
  ///
  /// Automatically validates that the key is of the correct type,
  /// then delegates to the implementation-specific retrieval logic.
  ///
  /// Example:
  /// ```dart
  /// final list = SilhouetteList([SilhouetteString('hello')]);
  /// final item = list.forKey(SilhouetteInt(0)); // Returns 'hello'
  /// ```
  @useResult
  Value forKey(SilhouetteValue key) {
    if (key is! Key) {
      throw SilhouetteException(
        'Cannot index $runtimeType with $key.runtimeType - '
        'expected $Key.',
      );
    }
    return _valueForKey(key);
  }

  /// Implementation-specific key retrieval logic.
  ///
  /// This method is called after the key type has been validated.
  /// Implementations should handle bounds checking, key existence, etc.
  Value _valueForKey(Key key);
}

/// Represents the null value in templates.
///
/// This is a singleton class that represents the `null` value.
/// In templates, null values can't have properties accessed on them.
///
/// Example usage:
/// ```dart
/// final nullValue = SilhouetteNull();
/// ```
@immutable
final class SilhouetteNull extends SilhouetteValue with SilhouetteEquatable {
  /// The singleton instance of null.
  static const SilhouetteNull _instance = SilhouetteNull._();

  /// Returns the singleton null instance.
  factory SilhouetteNull() => _instance;

  /// Private constructor for singleton pattern.
  const SilhouetteNull._();

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) =>
      throw Exception('Can\'t access properties of null.');

  @override
  bool operator ==(Object other) =>
      identical(other, this) || other is SilhouetteNull;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'null';
}

/// Represents a string value in templates.
///
/// Provides access to common string properties and methods that can be
/// used in template expressions. Supports method chaining and various
/// string manipulation operations.
///
/// Available properties:
/// - `length`: The number of characters
/// - `isEmpty`/`isNotEmpty`: Whether the string has content
/// - `toUpperCase`/`toLowerCase`: Case conversion methods
///
/// Available methods:
/// - `substring(start, end: optional)`: Extract a portion of the string
/// - `replace(from, to, all: true)`: Replace text within the string
/// - `contains(text)`: Check if string contains substring
/// - `startsWith(text)`/`endsWith(text)`: Check string boundaries
/// - `split(separator)`: Split string into list
/// - `trim()`: Remove leading/trailing whitespace
///
/// Example usage:
/// ```dart
/// final text = SilhouetteString('Hello World');
/// // In template: {{ text.toUpperCase() }} renders as "HELLO WORLD"
/// // In template: {{ text.substring(0, end: 5) }} renders as "Hello"
/// ```
@immutable
final class SilhouetteString extends SilhouetteValue with SilhouetteEquatable {
  /// The string value.
  final String value;

  /// Creates a string value with the given [value].
  const SilhouetteString(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async {
    return switch (propertyName) {
      'toUpperCase' => SilhouetteString(value.toUpperCase()),
      'toLowerCase' => SilhouetteString(value.toLowerCase()),
      'isEmpty' => SilhouetteBool(value.isEmpty),
      'isNotEmpty' => SilhouetteBool(value.isNotEmpty),
      'length' => SilhouetteInt(value.length),
      'substring' => SilhouetteFunction((args) {
        final start = args.positional.isNotEmpty
            ? args.positional[0]
            : throw const SilhouetteException(
                'substring() requires start parameter',
              );
        if (start is! SilhouetteInt) {
          throw const SilhouetteException(
            'substring() start must be an integer',
          );
        }

        final endValue = args.named['end'];
        if (endValue == null) {
          return SilhouetteString(value.substring(start.value));
        } else if (endValue is SilhouetteInt) {
          return SilhouetteString(value.substring(start.value, endValue.value));
        } else {
          throw const SilhouetteException('substring() end must be an integer');
        }
      }),
      'replace' => SilhouetteFunction((args) {
        if (args.positional.length < 2) {
          throw const SilhouetteException(
            'replace() requires from and to parameters',
          );
        }
        final from = args.positional[0];
        final to = args.positional[1];
        if (from is! SilhouetteString || to is! SilhouetteString) {
          throw const SilhouetteException(
            'replace() arguments must be strings',
          );
        }

        final allValue = args.named['all'];
        final all = allValue == null
            ? const SilhouetteBool(true)
            : (allValue is SilhouetteBool
                  ? allValue
                  : throw const SilhouetteException(
                      'replace() all parameter must be a boolean',
                    ));
        if (all.value) {
          return SilhouetteString(value.replaceAll(from.value, to.value));
        } else {
          return SilhouetteString(value.replaceFirst(from.value, to.value));
        }
      }),
      'contains' => SilhouetteFunction((args) {
        if (args.positional.isEmpty) {
          throw const SilhouetteException(
            'contains() requires a search parameter',
          );
        }
        final search = args.positional[0];
        if (search is! SilhouetteString) {
          throw const SilhouetteException(
            'contains() argument must be a string',
          );
        }
        return SilhouetteBool(value.contains(search.value));
      }),
      'startsWith' => SilhouetteFunction((args) {
        if (args.positional.isEmpty) {
          throw const SilhouetteException(
            'startsWith() requires a search parameter',
          );
        }
        final search = args.positional[0];
        if (search is! SilhouetteString) {
          throw const SilhouetteException(
            'startsWith() argument must be a string',
          );
        }
        return SilhouetteBool(value.startsWith(search.value));
      }),
      'endsWith' => SilhouetteFunction((args) {
        if (args.positional.isEmpty) {
          throw const SilhouetteException(
            'endsWith() requires a search parameter',
          );
        }
        final search = args.positional[0];
        if (search is! SilhouetteString) {
          throw const SilhouetteException(
            'endsWith() argument must be a string',
          );
        }
        return SilhouetteBool(value.endsWith(search.value));
      }),
      'split' => SilhouetteFunction((args) {
        if (args.positional.isEmpty) {
          throw const SilhouetteException(
            'split() requires a separator parameter',
          );
        }
        final separator = args.positional[0];
        if (separator is! SilhouetteString) {
          throw const SilhouetteException('split() separator must be a string');
        }
        final parts = value.split(separator.value);
        return SilhouetteList(parts.map(SilhouetteString.new).toList());
      }),
      'trim' => SilhouetteFunction((args) {
        return SilhouetteString(value.trim());
      }),
      _ => throw UnknownPropertyException(propertyName),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilhouetteString && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Represents a boolean value in templates.
///
/// Used for conditional logic and boolean operations. In templates,
/// boolean values render as their string representation ('true' or 'false').
///
/// Example usage:
/// ```dart
/// final isActive = SilhouetteBool(true);
/// // In template: {{ isActive }} renders as "true"
/// ```
@immutable
final class SilhouetteBool extends SilhouetteValue with SilhouetteEquatable {
  /// The boolean value.
  final bool value;

  /// Creates a boolean value with the given [value].
  const SilhouetteBool(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) =>
      throw UnknownPropertyException(propertyName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilhouetteBool && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Abstract base class for numeric values.
///
/// Provides common functionality for both integer and floating-point
/// numbers, including access to numeric properties and methods.
///
/// Available methods (implemented by subclasses):
/// - Mathematical operations: `abs()`, `round()`, `floor()`, `ceil()`
/// - Formatting: `toStringAsFixed(precision)`
@immutable
abstract base class SilhouetteNumber extends SilhouetteValue
    with SilhouetteEquatable {
  /// The numeric value as a Dart [num].
  num get value;

  /// Creates a new numeric value.
  const SilhouetteNumber();

  @override
  String toString() => value.toString();
}

/// Represents an integer value in templates.
///
/// Provides access to integer-specific properties and
/// inherits numeric methods from [SilhouetteNumber].
///
/// Available properties:
/// - `isEven`: Whether the number is even
/// - `isOdd`: Whether the number is odd
///
/// Example usage:
/// ```dart
/// final count = SilhouetteInt(42);
/// // In template: {{ count.isEven }} renders as "true"
/// ```
@immutable
final class SilhouetteInt extends SilhouetteNumber {
  @override
  final int value;

  /// Creates an integer value with the given [value].
  const SilhouetteInt(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async {
    return switch (propertyName) {
      'isEven' => SilhouetteBool(value.isEven),
      'isOdd' => SilhouetteBool(value.isOdd),
      'abs' => SilhouetteFunction((args) {
        return SilhouetteInt(value.abs());
      }),
      'round' => SilhouetteFunction((args) {
        return this;
      }),
      'floor' => SilhouetteFunction((args) {
        return this;
      }),
      'ceil' => SilhouetteFunction((args) {
        return this;
      }),
      'toStringAsFixed' => SilhouetteFunction((args) {
        if (args.positional.isEmpty) {
          throw const SilhouetteException(
            'toStringAsFixed() requires precision parameter',
          );
        }
        final precision = args.positional[0];
        if (precision is! SilhouetteInt) {
          throw const SilhouetteException(
            'toStringAsFixed() precision must be an integer',
          );
        }
        return SilhouetteString(value.toStringAsFixed(precision.value));
      }),
      _ => throw UnknownPropertyException(propertyName),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilhouetteInt && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Represents a floating-point number value in templates.
///
/// Inherits numeric methods from [SilhouetteNumber].
///
/// Example usage:
/// ```dart
/// final price = SilhouetteDouble(19.99);
/// // In template: {{ price.toStringAsFixed(2) }} renders as "19.99"
/// ```
@immutable
final class SilhouetteDouble extends SilhouetteNumber {
  @override
  final double value;

  /// Creates a double value with the given [value].
  const SilhouetteDouble(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async {
    return switch (propertyName) {
      'abs' => SilhouetteFunction((args) {
        return SilhouetteDouble(value.abs());
      }),
      'round' => SilhouetteFunction((args) {
        return SilhouetteInt(value.round());
      }),
      'floor' => SilhouetteFunction((args) {
        return SilhouetteInt(value.floor());
      }),
      'ceil' => SilhouetteFunction((args) {
        return SilhouetteInt(value.ceil());
      }),
      'toStringAsFixed' => SilhouetteFunction((args) {
        if (args.positional.isEmpty) {
          throw const SilhouetteException(
            'toStringAsFixed() requires precision parameter',
          );
        }
        final precision = args.positional[0];
        if (precision is! SilhouetteInt) {
          throw const SilhouetteException(
            'toStringAsFixed() precision must be an integer',
          );
        }
        return SilhouetteString(value.toStringAsFixed(precision.value));
      }),
      _ => throw UnknownPropertyException(propertyName),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilhouetteDouble && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Represents a list/array value in templates.
///
/// Supports indexing with integer indices and provides access to common
/// list properties and methods. List elements can be of any [SilhouetteValue]
/// type, but the type parameter allows for type-safe usage when all elements
/// are known to be the same type.
///
/// Available properties:
/// - `length`: The number of items in the list
/// - `isEmpty`/`isNotEmpty`: Whether the list has items
/// - `first`/`last`: First and last elements (throws if empty)
///
/// Available methods:
/// - `join(separator)`: Join elements into a string.
/// - `reverse()`: Return a reversed copy of the list.
/// - `contains(item)`: Check if list contains an item.
/// - `slice(start: 0, end: optional)`: Extract a portion.
///
/// Example usage:
/// ```dart
/// final items = SilhouetteList([
///   SilhouetteString('apple'),
///   SilhouetteString('banana'),
/// ]);
/// // In template: {{ items[0] }} renders as "apple"
/// // In template: {{ items.length }} renders as "2"
/// // In template: {{ items.join(', ') }} renders as "apple, banana"
/// // In template: {{ items.slice(start: 1, end: 3) }} renders as sublist
/// ```
@immutable
final class SilhouetteList<Value extends SilhouetteValue>
    extends SilhouetteValue
    with SilhouetteIndexable<SilhouetteInt, Value> {
  /// The list of values.
  final List<Value> value;

  /// Creates a list value with the given [value] list.
  const SilhouetteList(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async {
    return switch (propertyName) {
      'length' => SilhouetteInt(value.length),
      'isEmpty' => SilhouetteBool(value.isEmpty),
      'isNotEmpty' => SilhouetteBool(value.isNotEmpty),
      'first' =>
        value.isEmpty
            ? throw const SilhouetteException(
                'Cannot get first element of empty list',
              )
            : value.first,
      'last' =>
        value.isEmpty
            ? throw const SilhouetteException(
                'Cannot get last element of empty list',
              )
            : value.last,
      'join' => SilhouetteFunction((args) {
        final separator = args.positional.isNotEmpty
            ? args.positional[0]
            : const SilhouetteString('');

        if (separator is! SilhouetteString) {
          throw const SilhouetteException('join() separator must be a string');
        }

        final joined = value.map((v) => v.toString()).join(separator.value);
        return SilhouetteString(joined);
      }),
      'reverse' => SilhouetteFunction((args) {
        return SilhouetteList(value.reversed.toList());
      }),
      'contains' => SilhouetteFunction((args) {
        if (args.positional.isEmpty) {
          throw const SilhouetteException(
            'contains() requires an item parameter',
          );
        }
        final item = args.positional[0];
        return SilhouetteBool(value.any((v) => v == item));
      }),
      'slice' => SilhouetteFunction((args) {
        final startValue = args.named['start'] ?? const SilhouetteInt(0);
        final endValue = args.named['end'];

        if (startValue is! SilhouetteInt) {
          throw const SilhouetteException('slice() start must be an integer');
        }

        if (endValue != null && endValue is! SilhouetteInt) {
          throw const SilhouetteException('slice() end must be an integer');
        }

        final startIndex = startValue.value.clamp(0, value.length);

        if (endValue == null) {
          return SilhouetteList(value.sublist(startIndex));
        }
        final endIndex = (endValue as SilhouetteInt).value.clamp(
          startIndex,
          value.length,
        );
        return SilhouetteList(value.sublist(startIndex, endIndex));
      }),
      _ => throw UnknownPropertyException(propertyName),
    };
  }

  @override
  Value _valueForKey(SilhouetteInt key) {
    final index = key.value;
    if (index < 0 || index >= value.length) {
      throw UnknownKeyException(key);
    }

    return value[index];
  }

  @override
  String toString() => value.toString();
}

/// Represents a set value in templates.
///
/// Sets contain unique values and provide basic collection properties.
/// Elements must implement [SilhouetteEquatable] for
/// proper uniqueness checking.
///
/// Available properties:
/// - `length`: The number of items in the set
/// - `isEmpty`/`isNotEmpty`: Whether the set has items
///
/// Example usage:
/// ```dart
/// final tags = SilhouetteSet({
///   SilhouetteString('important'),
///   SilhouetteString('urgent'),
/// });
/// // In template: {{ tags.length }} renders as "2"
/// ```
@immutable
final class SilhouetteSet<Value extends SilhouetteEquatable>
    extends SilhouetteValue {
  /// The set of values.
  final Set<Value> value;

  /// Creates a set value with the given [value] set.
  const SilhouetteSet(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async {
    return switch (propertyName) {
      'length' => SilhouetteInt(value.length),
      'isEmpty' => SilhouetteBool(value.isEmpty),
      'isNotEmpty' => SilhouetteBool(value.isNotEmpty),
      _ => throw UnknownPropertyException(propertyName),
    };
  }

  @override
  String toString() => value.toString();
}

/// Represents a map/dictionary value in templates.
///
/// Supports indexing with equatable keys and provides access to map
/// properties and operations. Both keys and values must be Silhouette
/// values, with keys implementing [SilhouetteEquatable] for proper lookups.
///
/// Available properties:
/// - `length`: The number of key-value pairs
/// - `isEmpty`/`isNotEmpty`: Whether the map has entries
/// - `keys`: A set of all keys in the map
/// - `values`: A list of all values in the map
///
/// Example usage:
/// ```dart
/// final user = SilhouetteMap({
///   SilhouetteString('name'): SilhouetteString('John'),
///   SilhouetteString('age'): SilhouetteInt(30),
/// });
/// // In template: {{ user['name'] }} renders as "John"
/// // In template: {{ user.length }} renders as "2"
/// ```
@immutable
final class SilhouetteMap<
  Key extends SilhouetteEquatable,
  Value extends SilhouetteValue
>
    extends SilhouetteValue
    with SilhouetteIndexable<Key, Value> {
  /// The map of key-value pairs.
  final Map<Key, Value> value;

  /// Creates a map value with the given [value] map.
  const SilhouetteMap(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async {
    return switch (propertyName) {
      'length' => SilhouetteInt(value.length),
      'isEmpty' => SilhouetteBool(value.isEmpty),
      'isNotEmpty' => SilhouetteBool(value.isNotEmpty),
      'keys' => SilhouetteSet(value.keys.toSet()),
      'values' => SilhouetteList(value.values.toList()),
      _ => throw UnknownPropertyException(propertyName),
    };
  }

  @override
  Value _valueForKey(Key key) {
    return value[key] ?? (throw UnknownKeyException(key));
  }

  @override
  String toString() => value.toString();
}

/// Represents structured data with named properties.
///
/// This is the most common way to pass complex objects to templates.
/// Properties are accessed by name either using
/// dot notation (`{{ user.name }}`) or bracket notation (`{{ user['name'] }}`).
///
/// Unlike [SilhouetteMap], only supports silhouette identifiers as keys,
/// for more convenient object-like access patterns common in templates.
///
/// Example usage:
/// ```dart
/// final user = SilhouetteObject({
///   SilhouetteIdentifier('name'): SilhouetteString('Dash'),
///   SilhouetteIdentifier('age'): SilhouetteInt(7),
///   SilhouetteIdentifier('email'): SilhouetteString('dash@flutter.dev'),
/// });
/// // In template: {{ user.name }} renders as "Dash"
/// // In template: {{ user['email'] }} renders as "dash@flutter.dev"
/// ```
@immutable
final class SilhouetteObject extends SilhouetteValue
    with SilhouetteIndexable<SilhouetteString, SilhouetteValue> {
  /// The map of property names to values.
  @internal
  final Map<SilhouetteIdentifier, SilhouetteValue> value;

  /// Creates a data object with the given [value] properties.
  const SilhouetteObject(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async {
    return value[propertyName] ??
        (throw UnknownPropertyException(propertyName));
  }

  @override
  SilhouetteValue _valueForKey(SilhouetteString key) {
    return value[SilhouetteIdentifier(key.value)] ??
        (throw UnknownPropertyException(key.value));
  }

  @override
  String toString() => value.toString();
}

/// Represents a callable function in templates.
///
/// Functions can be called from templates with
/// both positional and named arguments.
/// The function implementation receives a [SilhouetteArguments] object
/// containing the parsed arguments and can return any [SilhouetteValue].
///
/// Example usage:
/// ```dart
/// final formatter = SilhouetteFunction((args) {
///   final template = args.positional[0] as SilhouetteString;
///   final name = args.named['name'] as SilhouetteString;
///   return SilhouetteString('${template.value} ${name.value}');
/// });
/// // In template: {{ formatter('Hello', name: 'World') }} renders as "Hello World"
/// ```
final class SilhouetteFunction extends SilhouetteValue {
  /// The function implementation.
  ///
  /// Takes parsed arguments and returns a result value. Can be async.
  final FutureOr<SilhouetteValue> Function(SilhouetteArguments) value;

  /// Creates a function value with the given implementation.
  const SilhouetteFunction(this.value);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) {
    throw UnknownPropertyException(propertyName);
  }

  /// Calls the function with the given [arguments].
  ///
  /// This method is used internally by the template evaluator when
  /// function call expressions are encountered in templates.
  Future<SilhouetteValue> call(SilhouetteArguments arguments) async {
    final result = value(arguments);
    return switch (result) {
      Future<SilhouetteValue>() => await result,
      _ => result,
    };
  }

  @override
  String toString() => value.toString();
}

/// Container for function call arguments.
///
/// Holds both positional and named arguments passed
/// to function calls in templates.
/// Used by [SilhouetteFunction] implementations to
/// access the arguments provided by template expressions.
///
/// Example:
/// ```dart
/// // For call: {{ func(1, 2, name: 'John', active: true) }}
/// final args = SilhouetteArguments(
///   positional: [SilhouetteInt(1), SilhouetteInt(2)],
///   named: {
///     SilhouetteIdentifier('name'): SilhouetteString('John'),
///     SilhouetteIdentifier('active'): SilhouetteBool(true),
///   },
/// );
/// ```
final class SilhouetteArguments {
  /// The positional arguments in order.
  final List<SilhouetteValue> positional;

  /// The named arguments mapped by parameter name.
  final Map<SilhouetteIdentifier, SilhouetteValue> named;

  /// Creates an arguments container that
  /// can be passed to a [SilhouetteFunction].
  ///
  /// Both [positional] and [named] are required but can be empty.
  SilhouetteArguments({required this.positional, required this.named});
}
