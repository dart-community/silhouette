import 'package:meta/meta.dart';

/// Utilities for parsing and validating characters as UTF-16 code units.
@internal
abstract final class Chars {
  /// The code unit for an underscore ('_').
  static const int underscore = 0x5F;

  /// The code unit for a zero ('0').
  static const int zero = 0x30;

  /// The code unit for a nine ('9').
  static const int nine = 0x39;

  /// The code unit for an uppercase A ('A').
  static const int upperA = 0x41;

  /// The code unit for an uppercase Z ('Z').
  static const int upperZ = 0x5A;

  /// The code unit for a lowercase A ('a').
  static const int lowerA = 0x61;

  /// The code unit for a lowercase Z ('z').
  static const int lowerZ = 0x7A;

  /// The code unit for a lowercase N ('n').
  static const int lowerN = 0x6E;

  /// The code unit for a lowercase T ('t').
  static const int lowerT = 0x74;

  /// The code unit for a lowercase R ('r').
  static const int lowerR = 0x72;

  /// The code unit for an open brace ('{').
  static const int openBrace = 0x7B;

  /// The code unit for a close brace ('}').
  static const int closeBrace = 0x7D;

  /// The code unit for a minus ('-').
  static const int minus = 0x2D;

  /// The code unit for a hash ('#').
  static const int hash = 0x23;

  /// The code unit for a space (' ').
  static const int space = 0x20;

  /// The code unit for a tab ('\t').
  static const int tab = 0x09;

  /// The code unit for a newline ('\n').
  static const int newline = 0x0A;

  /// The code unit for a carriage return ('\r').
  static const int carriageReturn = 0x0D;

  /// The code unit for a single quote ('\'').
  static const int singleQuote = 0x27;

  /// The code unit for a double quote ('"').
  static const int doubleQuote = 0x22;

  /// The code unit for a backslash ('\\').
  static const int backslash = 0x5C;

  /// The code unit for a dot ('.').
  static const int dot = 0x2E;

  /// The code unit for an open parenthesis ('(').
  static const int openParen = 0x28;

  /// The code unit for a close parenthesis (')').
  static const int closeParen = 0x29;

  /// The code unit for a comma (',').
  static const int comma = 0x2C;

  /// The code unit for a colon (':').
  static const int colon = 0x3A;

  /// The code unit for a slash ('/').
  static const int slash = 0x2F;

  /// The code unit for an open square bracket ('[').
  static const int openSquare = 0x5B;

  /// The code unit for a close square bracket (']').
  static const int closeSquare = 0x5D;

  /// Checks if a character code represents a digit (0-9).
  ///
  /// Returns `true` if [char] is a UTF-16 code unit representing
  /// a decimal digit character ('0' through '9').
  ///
  /// Returns `false` if [char] is `null` or not a digit.
  @useResult
  static bool isDigit(int? char) =>
      char != null && char >= zero && char <= nine;

  /// Checks if a character code represents a letter (a-z, A-Z).
  ///
  /// Returns `true` if [char] is a UTF-16 code unit representing
  /// an ASCII letter (either uppercase 'A'-'Z' or lowercase 'a'-'z').
  ///
  /// Returns `false` if [char] is `null` or not a letter.
  @useResult
  static bool isAlpha(int? char) =>
      char != null &&
      ((char >= upperA && char <= upperZ) ||
          (char >= lowerA && char <= lowerZ));

  /// Checks if a character code represents a letter or digit.
  ///
  /// Returns `true` if [char] is either a letter (a-z, A-Z) or
  /// a digit (0-9).
  ///
  /// Returns `false` if [char] is `null` or neither a letter nor digit.
  @useResult
  static bool isAlphaNumeric(int? char) => isAlpha(char) || isDigit(char);
}
