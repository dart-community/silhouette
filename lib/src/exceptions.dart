import 'package:meta/meta.dart';

import 'token.dart';
import 'value.dart';

/// Exception thrown during Silhouette template evaluation.
///
/// This exception is thrown when errors occur during template evaluation,
/// such as undefined variables, type mismatches, or invalid operations.
///
/// Example scenarios that might throw this exception:
/// - Accessing undefined variables: `{{ undefinedVar }}`
/// - Type mismatches: `{{ "string"[0] }}` (strings aren't indexable)
/// - Invalid function calls: `{{ notAFunction() }}`
/// - Statement evaluation errors
@immutable
final class SilhouetteException implements Exception {
  /// The message that describes this exception.
  final String message;

  /// Creates a template exception with the given [message].
  const SilhouetteException(this.message);

  @override
  String toString() => 'SilhouetteException: $message';
}

/// Exception thrown when attempting to access an unknown property.
///
/// This occurs when template code tries to access a property that doesn't
/// exist on a value type, such as `{{ "hello".nonExistentProperty }}`.
/// The exception includes the property name for better error reporting.
final class UnknownPropertyException extends SilhouetteException {
  /// The name of the property that was not found.
  final String propertyName;

  /// Creates an exception for the unknown [propertyName].
  const UnknownPropertyException(this.propertyName)
    : super('Unknown property: $propertyName');
}

/// Exception thrown when attempting to access an unknown key.
///
/// This occurs when template code tries to access a list index or
/// map key that doesn't exist, such as `{{ items[99] }}` for a short list
/// or `{{ data['missing'] }}` for a map without that key.
final class UnknownKeyException extends SilhouetteException {
  /// The key that was not found.
  final SilhouetteValue key;

  /// Creates an exception for the unknown [key].
  const UnknownKeyException(this.key) : super('Unknown key: $key');
}

/// Exception thrown when the parser encounters invalid template syntax.
///
/// Contains a descriptive message and optionally the token that caused
/// the error for better debugging and error reporting to users.
///
/// Example:
/// ```dart
/// try {
///   final parser = Parser('{{ invalid syntax }}');
///   parser.parse();
/// } catch (e) {
///   if (e is ParseException) {
///     print('Parse error: ${e.message}');
///     if (e.token != null) {
///       print('At token: ${e.token!.type} "${e.token!.value}"');
///     }
///   }
/// }
/// ```
@immutable
final class ParseException extends SilhouetteException {
  /// The token that caused the parse error, if available.
  ///
  /// Provides context about where in the template the error occurred.
  /// May be `null` for errors that don't relate to a specific token.
  final Token? token;

  /// Creates a new parse exception with the
  /// given [message] and optional [token].
  ///
  /// The [message] should describe what syntax was expected or what
  /// went wrong. The [token] should be the specific token that caused
  /// the error, if applicable.
  const ParseException(super.message, {this.token});

  @override
  String toString() {
    if (token case final token?) {
      final loc = token.location;
      return 'ParseException: $message\n'
          '  at line ${loc.line}, column ${loc.column}\n'
          '  token: ${token.type} "${token.value}"';
    }
    return 'ParseException: $message';
  }
}
