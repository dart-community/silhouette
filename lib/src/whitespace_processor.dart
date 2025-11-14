import 'package:meta/meta.dart';

import 'token.dart';

/// Post-processes a token stream to handle whitespace trimming.
///
/// This processor examines tokens with whitespace control flags
/// (set by the scanner when it encounters `{{-` or `-}}` syntax)
/// and trims adjacent text tokens accordingly.
/// This separation of concerns keeps the scanner simple and
/// makes whitespace handling easier to understand and test.
///
/// The processor handles two cases:
///
/// - Opening tags with [TokenWithWhitespaceControl.trimWhitespaceBefore]:
///   Trims trailing whitespace from the preceding text token.
/// - Closing tags with [TokenWithWhitespaceControl.trimWhitespaceAfter]:
///   Trims leading whitespace from the following text token.
///
/// Text tokens that become empty after trimming are
/// removed from the output.
///
/// Example:
/// ```dart
/// final rawTokens = scanner.scan('  {{- name -}}  ');
/// final processed = WhitespaceProcessor.process(rawTokens);
/// ```
@internal
abstract final class WhitespaceProcessor {
  /// Processes a list of tokens to apply whitespace trimming.
  ///
  /// Takes a token stream from the scanner and returns a new list
  /// with whitespace trimming applied based on token flags.
  ///
  /// Returns a new list of tokens with:
  ///
  /// - Text tokens trimmed according to adjacent whitespace flags.
  /// - Empty text tokens removed.
  /// - All other tokens preserved as-is.
  @useResult
  static List<Token> process(List<Token> tokens) {
    final result = <Token>[];
    var skipNext = false;

    for (var i = 0; i < tokens.length; i++) {
      // Skip token if it was already processed.
      if (skipNext) {
        skipNext = false;
        continue;
      }

      final token = tokens[i];

      // Check if token has whitespace control flags.
      final trimBefore =
          token is TokenWithWhitespaceControl && token.trimWhitespaceBefore;
      final trimAfter =
          token is TokenWithWhitespaceControl && token.trimWhitespaceAfter;

      // Handle openTag or openComment with trimWhitespaceBefore flag.
      if ((token.type == TokenType.openTag ||
              token.type == TokenType.openComment) &&
          trimBefore) {
        // Trim trailing whitespace from the previous text token.
        if (result.isNotEmpty && result.last.type == TokenType.text) {
          final lastToken = result.removeLast();
          final trimmed = lastToken.value.trimRight();
          if (trimmed.isNotEmpty) {
            result.add(Token(TokenType.text, trimmed, lastToken.location));
          }
        }
      }

      // Handle closeTag or closeComment with trimWhitespaceAfter flag.
      if ((token.type == TokenType.closeTag ||
              token.type == TokenType.closeComment) &&
          trimAfter) {
        // Add the close tag as a plain Token (no flags).
        result.add(Token(token.type, token.value, token.location));

        // Trim leading whitespace from the next text token.
        if (i + 1 < tokens.length && tokens[i + 1].type == TokenType.text) {
          final nextToken = tokens[i + 1];
          final trimmed = nextToken.value.trimLeft();
          if (trimmed.isNotEmpty) {
            result.add(Token(TokenType.text, trimmed, nextToken.location));
          }
          skipNext = true; // Skip the next token since we've handled it.
        }
        continue;
      }

      // Add token as a plain Token (strips any whitespace control flags).
      result.add(Token(token.type, token.value, token.location));
    }

    return result;
  }
}
