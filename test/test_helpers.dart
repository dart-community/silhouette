import 'package:silhouette/src/token.dart';

/// Creates a placeholder source location for testing purposes.
///
/// Provides a convenient way to create tokens with location information
/// in tests without needing to specify realistic line/column values.
const SourceLocation placeholderLocation = SourceLocation(
  line: 1,
  column: 1,
  offset: 0,
  length: 0,
);

/// Creates a token with a placeholder location for testing.
///
/// This is a convenience function for tests that need to create tokens
/// but don't care about the actual source location information.
Token testToken(TokenType type, String value) {
  return Token(type, value, placeholderLocation);
}
