import 'package:meta/meta.dart';

import 'chars.dart';
import 'token.dart';

/// A token-based scanner for the Silhouette template language.
///
/// The scanner converts raw template text into a stream of tokens that
/// can be processed by a parser.
/// It recognizes text outside of tags and
/// expressions within `{{ }}` delimiters.
///
/// The scanner operates in two modes:
/// - **Outside tags**: Collects literal text content until it encounters `{{`
/// - **Inside tags**: Tokenizes expressions, operators, and literals until `}}`
///
/// Example usage:
/// ```dart
/// final scanner = Scanner('Hello {{ name }}!');
/// final tokens = scanner.scan();
/// ```
final class Scanner {
  /// The UTF-16 code units of the input template string.
  final List<int> _codeUnits;

  /// Current position in the [_codeUnits] list.
  int _position = 0;

  /// Current line number in the source template (1-based).
  ///
  /// Incremented each time a newline character is encountered.
  /// The first line of the template is line 1.
  int _line = 1;

  /// Current column number in the source template (1-based).
  ///
  /// Incremented as characters are consumed, and reset to 1
  /// when a newline is encountered. The first column is column 1.
  int _column = 1;

  /// Whether the scanner is currently inside a template tag (`{{ }}`).
  ///
  /// When `true`, the scanner tokenizes expressions and operators.
  /// When `false`, the scanner collects literal text content.
  bool _insideTag = false;

  /// Creates a scanner for the given template [input].
  ///
  /// The input string is immediately converted to UTF-16 code units
  /// for efficient character-by-character processing.
  Scanner(String input) : _codeUnits = input.codeUnits;

  /// Scans the entire input and returns a list of tokens.
  ///
  /// This is the main entry point for lexical analysis.
  /// The method processes the input from start to finish, switching between
  /// text collection and expression tokenization as needed.
  ///
  /// The returned list always ends with an [TokenType.endOfFile] token.
  @useResult
  List<Token> scan() {
    final tokens = <Token>[];

    while (!_isAtEnd()) {
      if (_insideTag) {
        _scanInsideTag(tokens);
      } else {
        _scanOutsideTag(tokens);
      }
    }

    tokens.add(
      Token(
        TokenType.endOfFile,
        '',
        _createLocation(offset: _position, length: 0),
      ),
    );

    return tokens;
  }

  /// Scans text content outside of template tags.
  ///
  /// Collects literal text until encountering a tag opening (`{{`) or
  /// a comment opening (`{{#`). Text tokens are emitted as-is; whitespace
  /// trimming is handled by post-processing.
  void _scanOutsideTag(List<Token> tokens) {
    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    while (!_isAtEnd() && !_isDoubleBraceOpening()) {
      _advance();
    }

    final text = String.fromCharCodes(_codeUnits, startOffset, _position);

    if (text.isNotEmpty) {
      final location = SourceLocation(
        line: startLine,
        column: startColumn,
        offset: startOffset,
        length: text.length,
      );
      tokens.add(Token(TokenType.text, text, location));
    }

    if (!_isAtEnd()) {
      // Check if it's a comment (`{{#`) or a regular tag (`{{`).
      if (_peekAt(2) == Chars.hash) {
        _handleCommentOpening(tokens);
      } else {
        _handleTagOpening(tokens);
      }
    }
  }

  /// Checks if the current position is at a double brace opening (`{{`).
  ///
  /// This is used as the start of both regular tags (`{{ }}`) and
  /// comments (`{{# #}}`).
  bool _isDoubleBraceOpening() =>
      !_isAtEnd() &&
      _peek() == Chars.openBrace &&
      _peekNext() == Chars.openBrace;

  /// Handles the opening of a template tag (`{{` sequence).
  ///
  /// Detects optional whitespace trimming modifiers and transitions
  /// the scanner into tag mode. If the tag starts with `{{-`, the
  /// opening tag token is marked to trim whitespace before it.
  void _handleTagOpening(List<Token> tokens) {
    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    // Consume the first `{` character.
    _advance();
    // Consume the second `{` character.
    _advance();

    // Check for whitespace trimming modifier.
    final trimBefore = !_isAtEnd() && _peek() == Chars.minus;
    if (trimBefore) {
      // Consume the `-` character.
      _advance();
      _skipWhitespace();
    }

    final location = SourceLocation(
      line: startLine,
      column: startColumn,
      offset: startOffset,
      length: trimBefore ? 3 : 2,
    );

    tokens.add(
      TokenWithWhitespaceControl(
        TokenType.openTag,
        '{{',
        location,
        trimWhitespaceBefore: trimBefore,
      ),
    );
    _insideTag = true;
  }

  /// Handles the opening of a comment block (`{{#` sequence).
  ///
  /// Emits an openComment token with optional whitespace trimming flags.
  /// If the comment starts with `{{#-`, the token is marked to trim
  /// whitespace before it. The comment content is consumed until the
  /// closing delimiter is found, at which point a [TokenType.closeComment]
  /// is emitted.
  ///
  /// Comments support whitespace control modifiers:
  /// - `{{#-` trims trailing whitespace from the preceding text token
  /// - `-#}}` trims leading whitespace from the following text token
  ///
  /// Example:
  /// ```dart
  /// 'text  {{#- comment -#}}  more'
  /// // Produces tokens with whitespace control flags
  /// ```
  void _handleCommentOpening(List<Token> tokens) {
    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    // Consume the first `{` character.
    _advance();

    // Consume the second `{` character.
    _advance();

    // Consume the `#` character.
    _advance();

    // Check for whitespace trimming modifier.
    final trimBefore = !_isAtEnd() && _peek() == Chars.minus;
    if (trimBefore) {
      // Consume the `-` character.
      _advance();
      _skipWhitespace();
    }

    final location = SourceLocation(
      line: startLine,
      column: startColumn,
      offset: startOffset,
      length: trimBefore ? 4 : 3,
    );

    tokens.add(
      TokenWithWhitespaceControl(
        TokenType.openComment,
        '{{#',
        location,
        trimWhitespaceBefore: trimBefore,
      ),
    );

    // Consume comment content until we find the closing delimiter.
    _scanCommentContent(tokens);
  }

  /// Scans the content of a comment and emits the closing token.
  ///
  /// Consumes all characters within the comment until finding the
  /// closing `#}}` or `-#}}` sequence. Emits a [TokenType.closeComment]
  /// with appropriate whitespace control flags.
  void _scanCommentContent(List<Token> tokens) {
    while (!_isAtEnd()) {
      // Check for closing sequence: `-#}}` or `#}}`.
      if (_peek() == Chars.minus &&
          _peekNext() == Chars.hash &&
          _peekAt(2) == Chars.closeBrace &&
          _peekAt(3) == Chars.closeBrace) {
        // Found `-#}}` closing with trim after.
        _handleCommentClosing(tokens, trimAfter: true);
        return;
      } else if (_peek() == Chars.hash &&
          _peekNext() == Chars.closeBrace &&
          _peekAt(2) == Chars.closeBrace) {
        // Found `#}}` closing without trim.
        _handleCommentClosing(tokens, trimAfter: false);
        return;
      }

      // Still inside the comment, keep consuming.
      _advance();
    }

    // If we reach here, the comment was never closed.
    // For robustness, just return and let the scanner continue.
  }

  /// Handles the closing of a comment block (`#}}` or `-#}}` sequence).
  ///
  /// Emits a [TokenType.closeComment] with optional whitespace trimming flags.
  /// If the comment ends with `-#}}`, the token is marked to trim
  /// whitespace after it.
  void _handleCommentClosing(List<Token> tokens, {required bool trimAfter}) {
    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    if (trimAfter) {
      // Consume the '-' character.
      _advance();
    }

    // Consume the `#` character.
    _advance();
    // Consume the first `}` character.
    _advance();
    // Consume the second `}` character.
    _advance();

    final location = SourceLocation(
      line: startLine,
      column: startColumn,
      offset: startOffset,
      length: trimAfter ? 4 : 3,
    );

    tokens.add(
      TokenWithWhitespaceControl(
        TokenType.closeComment,
        '#}}',
        location,
        trimWhitespaceAfter: trimAfter,
      ),
    );
  }

  /// Scans expressions and operators inside template tags.
  ///
  /// Processes the content between `{{` and `}}` delimiters, tokenizing
  /// identifiers, literals, operators, and other expression components.
  /// Also handles tag closing with optional whitespace trimming.
  void _scanInsideTag(List<Token> tokens) {
    _skipWhitespace();

    if (_isAtEnd()) return;

    // Check for tag closing with optional whitespace trimming.
    if (_isTagClosing()) {
      _handleTagClosing(tokens);
      return;
    }

    // Scan different token types.
    // Try number literals before single-char tokens to handle negative numbers.
    final token =
        _scanNumberLiteral() ??
        _scanSingleCharToken() ??
        _scanStringLiteral() ??
        _scanIdentifierOrKeyword();

    if (token != null) {
      tokens.add(token);
    } else {
      // Unknown character - skip it for error recovery.
      _advance();
    }
  }

  /// Checks if the current position is at a tag closing sequence.
  ///
  /// Handles both regular closing (`}}`) and closing with
  /// whitespace trimming (`-}}`).
  bool _isTagClosing() {
    if (_isAtEnd()) return false;

    // Check for `-}}` pattern.
    if (_peek() == Chars.minus &&
        _peekNext() == Chars.closeBrace &&
        _peekAt(2) == Chars.closeBrace) {
      return true;
    }

    // Check for `}}` pattern.
    return _peek() == Chars.closeBrace && _peekNext() == Chars.closeBrace;
  }

  /// Handles the closing of a template tag (`}}` or `-}}` sequence).
  ///
  /// Detects optional whitespace trimming modifiers and transitions
  /// the scanner out of tag mode.
  void _handleTagClosing(List<Token> tokens) {
    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    // Check for whitespace trimming modifier.
    final trimAfter = !_isAtEnd() && _peek() == Chars.minus;
    if (trimAfter) {
      _advance(); // Consume -
    }

    // Must have `}}` at this point (verified by `_isTagClosing`).
    _advance(); // First }
    _advance(); // Second }

    final location = SourceLocation(
      line: startLine,
      column: startColumn,
      offset: startOffset,
      length: trimAfter ? 3 : 2,
    );

    tokens.add(
      TokenWithWhitespaceControl(
        TokenType.closeTag,
        '}}',
        location,
        trimWhitespaceAfter: trimAfter,
      ),
    );
    _insideTag = false;
  }

  /// Attempts to scan a single character token.
  ///
  /// Recognizes operators, delimiters, and other single-character
  /// tokens used in template expressions. Returns `null` if the
  /// current character doesn't match any known single-character token.
  @useResult
  Token? _scanSingleCharToken() {
    if (_isAtEnd()) return null;

    return switch (_peek()) {
      Chars.openParen => _createTokenAndAdvance(TokenType.openParenthesis, '('),
      Chars.closeParen => _createTokenAndAdvance(
        TokenType.closeParenthesis,
        ')',
      ),
      Chars.comma => _createTokenAndAdvance(TokenType.comma, ','),
      Chars.colon => _createTokenAndAdvance(TokenType.colon, ':'),
      Chars.dot => _createTokenAndAdvance(TokenType.dot, '.'),
      Chars.slash => _createTokenAndAdvance(TokenType.slash, '/'),
      Chars.openSquare => _createTokenAndAdvance(
        TokenType.openSquareBracket,
        '[',
      ),
      Chars.closeSquare => _createTokenAndAdvance(
        TokenType.closeSquareBracket,
        ']',
      ),
      // Only treat minus as a token if not followed by a closing brace.
      // This prevents consuming the minus in a `-}}` sequence.
      Chars.minus when _peekNext() != Chars.closeBrace =>
        _createTokenAndAdvance(TokenType.minus, '-'),
      _ => null,
    };
  }

  /// Creates a token with the given type and value, then advances position.
  ///
  /// This is a utility method for single-character tokens that combines
  /// token creation with position advancement for cleaner code.
  Token _createTokenAndAdvance(TokenType type, String value) {
    final location = _createLocation(offset: _position, length: 1);
    _advance();
    return Token(type, value, location);
  }

  /// Attempts to scan a string literal token.
  ///
  /// Recognizes strings enclosed in single or double quotes, including
  /// support for escape sequences. Returns `null` if the current position
  /// doesn't start a string literal.
  ///
  /// Supported escape sequences:
  /// - `\n` → newline
  /// - `\t` → tab
  /// - `\r` → carriage return
  /// - `\\` → backslash
  /// - `\'` → single quote
  /// - `\"` → double quote
  @useResult
  Token? _scanStringLiteral() {
    if (_isAtEnd()) return null;

    final quote = _peek();
    if (quote != Chars.singleQuote && quote != Chars.doubleQuote) {
      return null;
    }

    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    _advance(); // Consume opening quote.
    final buffer = StringBuffer();

    while (!_isAtEnd() && _peek() != quote) {
      if (_peek() == Chars.backslash) {
        _advance(); // Consume backslash.
        if (!_isAtEnd()) {
          final escaped = _advance();
          final char = _getEscapedCharacter(escaped);
          if (char != null) {
            buffer.write(char);
          } else {
            // Unknown escape sequence - include the character as-is.
            buffer.write(String.fromCharCode(escaped));
          }
        }
      } else {
        buffer.write(String.fromCharCode(_advance()));
      }
    }

    if (!_isAtEnd()) {
      _advance(); // Consume closing quote.
    }

    final location = SourceLocation(
      line: startLine,
      column: startColumn,
      offset: startOffset,
      length: _position - startOffset,
    );
    return Token(TokenType.stringLiteral, buffer.toString(), location);
  }

  /// Converts an escape sequence to its character representation.
  ///
  /// Maps escape sequence characters to their actual character values.
  /// Returns `null` for unknown escape sequences, which are then
  /// included as-is in the string.
  String? _getEscapedCharacter(int escaped) => switch (escaped) {
    Chars.lowerN => '\n',
    Chars.lowerT => '\t',
    Chars.lowerR => '\r',
    Chars.backslash => '\\',
    Chars.singleQuote => '\'',
    Chars.doubleQuote => '"',
    _ => null,
  };

  /// Attempts to scan a numeric literal token.
  ///
  /// Recognizes both integer and decimal numbers, including negative numbers.
  /// Returns `null` if the current position doesn't start with a digit or
  /// a minus sign followed by a digit.
  ///
  /// Supported formats:
  /// - Integers: `42`, `0`, `123`, `-5`, `-100`
  /// - Decimals: `3.14`, `0.5`, `123.456`, `-3.14`, `-0.5`
  @useResult
  Token? _scanNumberLiteral() {
    if (_isAtEnd()) return null;

    final current = _peek();
    final next = _peekNext();

    // Check for negative number: minus followed immediately by a digit.
    final isNegative = current == Chars.minus && Chars.isDigit(next);

    // If not a digit and not a negative number, return null.
    if (!Chars.isDigit(current) && !isNegative) {
      return null;
    }

    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    final buffer = StringBuffer();

    // Consume minus sign if present.
    if (isNegative) {
      buffer.write(String.fromCharCode(_advance()));
    }

    // Scan integer part.
    while (!_isAtEnd() && Chars.isDigit(_peek())) {
      buffer.write(String.fromCharCode(_advance()));
    }

    // Scan decimal part if present.
    if (!_isAtEnd() && _peek() == Chars.dot && Chars.isDigit(_peekNext())) {
      buffer.write(String.fromCharCode(_advance())); // Consume .
      while (!_isAtEnd() && Chars.isDigit(_peek())) {
        buffer.write(String.fromCharCode(_advance()));
      }
    }

    final location = SourceLocation(
      line: startLine,
      column: startColumn,
      offset: startOffset,
      length: _position - startOffset,
    );
    return Token(TokenType.numberLiteral, buffer.toString(), location);
  }

  /// Attempts to scan an identifier or keyword token.
  ///
  /// Recognizes variable names, property names, and reserved keywords.
  /// Returns `null` if the current position doesn't start with a letter
  /// or underscore.
  ///
  /// Identifiers must start with a letter or underscore and can contain
  /// letters, digits, and underscores.
  @useResult
  Token? _scanIdentifierOrKeyword() {
    if (_isAtEnd()) return null;

    final current = _peek();
    if (!Chars.isAlpha(current) && current != Chars.underscore) {
      return null;
    }

    final startOffset = _position;
    final startLine = _line;
    final startColumn = _column;

    final buffer = StringBuffer();

    while (!_isAtEnd() &&
        (Chars.isAlphaNumeric(_peek()) || _peek() == Chars.underscore)) {
      buffer.write(String.fromCharCode(_advance()));
    }

    final value = buffer.toString();
    final tokenType = _getTokenTypeForIdentifier(value);
    final location = SourceLocation(
      line: startLine,
      column: startColumn,
      offset: startOffset,
      length: value.length,
    );
    return Token(tokenType, value, location);
  }

  /// Determines the token type for a given identifier string.
  ///
  /// Checks if the identifier matches any reserved keywords or boolean/null
  /// literals. Otherwise, treats it as a regular identifier.
  TokenType _getTokenTypeForIdentifier(String value) {
    return switch (value) {
      'true' => TokenType.trueKeyword,
      'false' => TokenType.falseKeyword,
      'null' => TokenType.nullKeyword,
      'if' ||
      'else' ||
      'for' ||
      'let' ||
      'set' ||
      'in' ||
      'include' ||
      'render' => TokenType.reservedKeyword,
      _ => TokenType.identifier,
    };
  }

  /// Skips whitespace characters at the current position.
  ///
  /// Advances the position past any sequence of space, tab, carriage
  /// return, or newline characters. Used when whitespace is not
  /// significant (inside template tags).
  void _skipWhitespace() {
    while (!_isAtEnd() && _isWhitespace(_peek())) {
      _advance();
    }
  }

  /// Checks if the given character is a whitespace character.
  bool _isWhitespace(int char) => switch (char) {
    Chars.space || Chars.tab || Chars.carriageReturn || Chars.newline => true,
    _ => false,
  };

  /// Advances the current position and returns the consumed character.
  ///
  /// Also updates line and column tracking. This method should only be
  /// called when [_isAtEnd] is false.
  int _advance() {
    assert(!_isAtEnd(), 'Cannot advance past end of input');

    final char = _codeUnits[_position++];

    // Update line and column tracking.
    if (char == Chars.newline) {
      _line++;
      _column = 1;
    } else {
      _column++;
    }

    return char;
  }

  /// Returns the current character without advancing the position.
  ///
  /// Returns the character at the current position. This method should
  /// only be called when [_isAtEnd] is false.
  int _peek() {
    assert(!_isAtEnd(), 'Cannot peek past end of input');
    return _codeUnits[_position];
  }

  /// Returns the next character without advancing the position.
  ///
  /// Returns the character at the next position, or 0 if the next
  /// position would be beyond the end of input. The value 0 is safe
  /// because it's not a valid character in template content.
  int _peekNext() => _peekAt(1);

  /// Returns the character at the given [offset] from current position.
  ///
  /// Returns the character at the offset position, or 0 if the offset
  /// position would be beyond the end of input. The value 0 is safe
  /// because it's not a valid character in template content.
  int _peekAt(int offset) {
    final index = _position + offset;
    return index >= _codeUnits.length ? 0 : _codeUnits[index];
  }

  /// Checks if the scanner has reached the end of the input.
  bool _isAtEnd() => _position >= _codeUnits.length;

  /// Creates a source location with the given parameters.
  ///
  /// Uses the current line and column if not at the specified offset.
  /// This is a helper method to reduce boilerplate when creating locations.
  SourceLocation _createLocation({required int offset, required int length}) {
    return SourceLocation(
      line: _line,
      column: _column,
      offset: offset,
      length: length,
    );
  }
}
