/// @docImport 'parser.dart';
/// @docImport 'scanner.dart';
/// @docImport 'whitespace_processor.dart';
library;

import 'package:meta/meta.dart';

/// Represents a position in the source template text.
///
/// Provides line, column, and offset information for
/// error reporting and debugging.
/// Line and column numbers are 1-based, while offset is 0-based.
@immutable
final class SourceLocation {
  /// The line number in the source template (1-based).
  ///
  /// The first line of the template is line 1.
  final int line;

  /// The column number in the source template (1-based).
  ///
  /// The first character on a line is column 1.
  final int column;

  /// The byte offset from the start of the source (0-based).
  ///
  /// Represents the index into the source string where
  /// this location begins.
  final int offset;

  /// The length of the token in characters.
  ///
  /// For multi-line tokens, this is the total character count
  /// including newline characters.
  final int length;

  /// Creates a new source location.
  const SourceLocation({
    required this.line,
    required this.column,
    required this.offset,
    required this.length,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceLocation &&
          line == other.line &&
          column == other.column &&
          offset == other.offset &&
          length == other.length;

  @override
  int get hashCode => Object.hash(line, column, offset, length);

  @override
  String toString() => 'line $line, column $column';
}

/// Represents a lexical token in the Silhouette template language.
///
/// Each token has a [type] that categorizes it,
/// a [value] containing the actual text content from the source template,
/// and a [location] indicating where in the source the token was found.
///
/// Tokens are produced by the [Scanner] and consumed by
/// the [Parser] to build the Abstract Syntax Tree (AST).
/// They preserve source location information for error reporting and debugging.
///
/// Example:
/// ```dart
/// final location = SourceLocation(
///   line: 1,
///   column: 4,
///   offset: 3,
///   length: 8,
/// );
/// final token = Token(TokenType.identifier, 'userName', location);
/// print(token); // Token(identifier, "userName" at line 1, column 4)
/// ```
@immutable
final class Token {
  /// The type category of this token.
  ///
  /// Determines how the parser will interpret and handle this token.
  final TokenType type;

  /// The textual content of this token.
  ///
  /// Contains the exact text from the source template that
  /// this token represents, preserving the original formatting and content.
  final String value;

  /// The source location where this token appears in the template.
  ///
  /// Used for error reporting and debugging to show users exactly
  /// where in their template an issue occurred.
  final SourceLocation location;

  /// Creates a new token with the given [type], [value], and [location].
  ///
  /// The [type] categorizes the token's role in the grammar, while
  /// [value] contains the actual text content from the source, and
  /// [location] indicates where the token was found.
  const Token(this.type, this.value, this.location);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => 'Token($type, "$value" at $location)';
}

/// A token with whitespace control metadata.
///
/// This subclass is used by the [Scanner] to emit tokens that contain
/// information about whitespace trimming modifiers (`{{-` and `-}}`).
/// The [WhitespaceProcessor] consumes these tokens and
/// returns plain [Token] instances, ensuring that
/// the parser and renderer don't need to handle whitespace control.
@internal
final class TokenWithWhitespaceControl extends Token {
  /// Whether to trim whitespace before this token.
  ///
  /// Used by opening tags with the `{{-` syntax to indicate that
  /// trailing whitespace from the preceding text should be trimmed.
  final bool trimWhitespaceBefore;

  /// Whether to trim whitespace after this token.
  ///
  /// Used by closing tags with the `-}}` syntax to indicate that
  /// leading whitespace from the following text should be trimmed.
  final bool trimWhitespaceAfter;

  /// Creates a token with whitespace control flags.
  const TokenWithWhitespaceControl(
    super.type,
    super.value,
    super.location, {
    this.trimWhitespaceBefore = false,
    this.trimWhitespaceAfter = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWithWhitespaceControl &&
          type == other.type &&
          value == other.value &&
          trimWhitespaceBefore == other.trimWhitespaceBefore &&
          trimWhitespaceAfter == other.trimWhitespaceAfter;

  @override
  int get hashCode => Object.hash(
    type,
    value,
    trimWhitespaceBefore,
    trimWhitespaceAfter,
  );

  @override
  String toString() =>
      'TokenWithWhitespaceControl($type, "$value" at $location, '
      'trimBefore: $trimWhitespaceBefore, trimAfter: $trimWhitespaceAfter)';
}

/// The types of tokens recognized by the Silhouette scanner.
///
/// Each token type represents a distinct category of
/// lexical element in the template language.
/// The scanner uses these types to categorize the input text, and the
/// parser uses them to understand the structure and meaning of the template.
enum TokenType {
  /// Plain text content outside of template tags.
  ///
  /// Represents literal text that should be output as-is without
  /// any processing. This includes all characters outside of `{{ }}`
  /// template delimiters.
  ///
  /// Example: In `Hello {{ name }}!`, there would be two text tokens:
  /// "Hello " and "!".
  text,

  /// Line break characters.
  ///
  /// Currently unused but reserved for future features that might
  /// need special handling of line breaks, such as whitespace control
  /// or line-based template directives.
  newLine,

  /// Marks the end of the input stream.
  ///
  /// This sentinel token is always added at the end of the token stream
  /// to simplify parser logic and provide a clear termination condition.
  endOfFile,

  /// Opening template tag delimiter: `{{`.
  ///
  /// Marks the beginning of a template expression that should be evaluated.
  /// Might include whitespace control modifiers like `{{-`.
  openTag,

  /// Closing template tag delimiter: `}}`.
  ///
  /// Marks the end of a template expression.
  /// Might include whitespace control modifiers like `-}}`.
  closeTag,

  /// Opening comment delimiter: `{{#`.
  ///
  /// Marks the beginning of a comment block that is removed from the output.
  /// Might include whitespace control modifiers like `{{#-`.
  openComment,

  /// Closing comment delimiter: `#}}`.
  ///
  /// Marks the end of a comment block.
  /// Might include whitespace control modifiers like `-#}}`.
  closeComment,

  /// Variable or function names.
  ///
  /// Represents user-defined identifiers such as variable names,
  /// property names, or function names. Must start with a letter
  /// or underscore and can contain letters, digits, and underscores.
  ///
  /// Examples: `name`, `user_id`, `firstName`, `_private`
  identifier,

  /// String literals enclosed in quotes.
  ///
  /// Represents text values enclosed in single or double quotes.
  /// Supports escape sequences for special characters like `\n`, `\t`,
  /// `\"`, `\'`, and `\\`.
  ///
  /// Examples: `"hello"`, `'world'`, `"line\nbreak"`
  stringLiteral,

  /// Numeric literals (integers and decimals).
  ///
  /// Represents numeric values, both integers and floating-point numbers.
  /// Integers are parsed as [int], while numbers with decimal points
  /// are parsed as [double].
  ///
  /// Examples: `42`, `3.14159`, `0`, `123.0`
  numberLiteral,

  /// The `true` boolean literal.
  ///
  /// Represents the boolean value true in template expressions.
  trueKeyword,

  /// The `false` boolean literal.
  ///
  /// Represents the boolean value false in template expressions.
  falseKeyword,

  /// The `null` literal.
  ///
  /// Represents the null value in template expressions.
  nullKeyword,

  /// Reserved keywords for future language features.
  ///
  /// Currently includes:
  /// - `if`
  /// - `else`
  /// - `for`
  /// - `let`
  /// - `set`
  /// - `in`
  /// - `include`
  /// - `render`
  ///
  /// These are reserved for future control flow and
  /// template composition features.
  ///
  /// Using these as identifiers will result in a parse error.
  reservedKeyword,

  /// Opening parenthesis: `(`.
  ///
  /// Used for function calls, method calls, and grouping expressions.
  /// Always paired with a corresponding [closeParenthesis].
  openParenthesis,

  /// Closing parenthesis: `)`.
  ///
  /// Used to close function calls, method calls, and grouped expressions.
  /// Always paired with a corresponding [openParenthesis].
  closeParenthesis,

  /// Comma separator: `,`.
  ///
  /// Used to separate function arguments, array elements, and other
  /// list-like constructs in template expressions.
  comma,

  /// Colon operator: `:`.
  ///
  /// Used in named function arguments to separate the parameter name
  /// from its value, such as `function(name: "John")`.
  colon,

  /// Dot operator for property access: `.`.
  ///
  /// Used to access properties and methods of objects,
  /// such as `user.name` or `text.toUpperCase`.
  dot,

  /// Slash operator: `/`.
  ///
  /// Reserved for future use in path operations or division.
  /// Currently recognized but not used in expression evaluation.
  slash,

  /// Minus operator: `-`.
  ///
  /// Can be used for arithmetic operations or as part of whitespace
  /// control modifiers in template tags (`{{-` or `-}}`).
  minus,

  /// Opening square bracket for indexing: `[`.
  ///
  /// Used for list indexing and map key access,
  /// such as `items[0]` or `data['key']`.
  /// Always paired with a corresponding [closeSquareBracket].
  openSquareBracket,

  /// Closing square bracket for indexing: `]`.
  ///
  /// Used to close list indexing and map key access expressions.
  /// Always paired with a corresponding [openSquareBracket].
  closeSquareBracket,
}
