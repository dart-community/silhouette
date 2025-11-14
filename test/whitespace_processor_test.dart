import 'package:silhouette/src/parser.dart';
import 'package:silhouette/src/scanner.dart';
import 'package:silhouette/src/token.dart';
import 'package:silhouette/src/whitespace_processor.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('WhitespaceProcessor', () {
    group('No trimming', () {
      test('passes through tokens without trim flags unchanged', () {
        final input = [
          testToken(TokenType.text, '  hello  '),
          testToken(TokenType.openTag, '{{'),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.text, '  world  '),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result.length, 6);
        expect(result[0].type, TokenType.text);
        expect(result[0].value, '  hello  ');
        expect(result[4].type, TokenType.text);
        expect(result[4].value, '  world  ');
      });

      test('handles empty token list', () {
        final result = WhitespaceProcessor.process([]);
        expect(result, isEmpty);
      });

      test('handles single token', () {
        final input = [testToken(TokenType.text, 'hello')];
        final result = WhitespaceProcessor.process(input);
        expect(result.length, 1);
        expect(result[0].value, 'hello');
      });
    });

    group('Trim before ({{-)', () {
      test('trims trailing whitespace from preceding text token', () {
        final input = [
          testToken(TokenType.text, 'hello   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].type, TokenType.text);
        expect(result[0].value, 'hello');
      });

      test('removes text token if only whitespace remains after trimming', () {
        final input = [
          testToken(TokenType.text, '   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // Text token should be removed entirely.
        expect(result[0].type, TokenType.openTag);
        expect(result.length, 4); // No text token.
      });

      test('trims tabs and newlines from preceding text', () {
        final input = [
          testToken(TokenType.text, 'hello\n\t  '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].value, 'hello');
      });

      test('does nothing if no preceding text token', () {
        final input = [
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result.length, 4);
        expect(result[0].type, TokenType.openTag);
      });

      test('handles consecutive trims before same tag', () {
        final input = [
          testToken(TokenType.text, 'a   '),
          testToken(TokenType.text, 'b   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // Only the immediately preceding text token should be trimmed.
        expect(result[0].value, 'a   ');
        expect(result[1].value, 'b');
      });
    });

    group('Trim after (-}})', () {
      test('trims leading whitespace from following text token', () {
        final input = [
          testToken(TokenType.openTag, '{{'),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[3].type, TokenType.text);
        expect(result[3].value, 'world');
      });

      test('removes text token if only whitespace remains after trimming', () {
        final input = [
          testToken(TokenType.openTag, '{{'),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   '),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // Text token should be removed entirely.
        expect(result[2].type, TokenType.closeTag);
        expect(result[3].type, TokenType.endOfFile);
        expect(result.length, 4); // No text token.
      });

      test('trims tabs and newlines from following text', () {
        final input = [
          testToken(TokenType.openTag, '{{'),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '  \n\t world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[3].value, 'world');
      });

      test('does nothing if no following text token', () {
        final input = [
          testToken(TokenType.openTag, '{{'),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result.length, 4);
        expect(result[2].type, TokenType.closeTag);
      });

      test('handles consecutive trims after same tag', () {
        final input = [
          testToken(TokenType.openTag, '{{'),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   a'),
          testToken(TokenType.text, '   b'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // Only the immediately following text token should be trimmed.
        expect(result[3].value, 'a');
        expect(result[4].value, '   b');
      });
    });

    group('Both trim before and after ({{- -}})', () {
      test('trims whitespace on both sides', () {
        final input = [
          testToken(TokenType.text, 'hello   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].value, 'hello');
        expect(result[4].value, 'world');
      });

      test('removes both text tokens if only whitespace', () {
        final input = [
          testToken(TokenType.text, '   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   '),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // Both text tokens removed.
        expect(result[0].type, TokenType.openTag);
        expect(result[3].type, TokenType.endOfFile);
        expect(result.length, 4);
      });
    });

    group('Multiple tags', () {
      test('handles multiple consecutive trimmed tags', () {
        final input = [
          testToken(TokenType.text, 'a   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'x'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'y'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   b'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].value, 'a');
        // Middle whitespace-only text token should be removed.
        expect(result[7].value, 'b');
      });

      test('handles mix of trimmed and non-trimmed tags', () {
        final input = [
          testToken(TokenType.text, 'a   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'x'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.text, '   b   '),
          testToken(TokenType.openTag, '{{'),
          testToken(TokenType.identifier, 'y'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   c'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].value, 'a');
        expect(result[4].value, '   b   '); // Not trimmed.
        expect(result[8].value, 'c'); // Leading trimmed.
      });
    });

    group('Edge cases', () {
      test('handles text token with no whitespace to trim', () {
        final input = [
          testToken(TokenType.text, 'hello'),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].value, 'hello');
      });

      test('handles empty text token', () {
        final input = [
          testToken(TokenType.text, ''),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // Empty text token should be removed during trimming.
        expect(result[0].type, TokenType.openTag);
      });

      test('preserves internal tag structure', () {
        final input = [
          testToken(TokenType.text, 'hello   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'user'),
          testToken(TokenType.dot, '.'),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.openParenthesis, '('),
          testToken(TokenType.closeParenthesis, ')'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // All internal tag tokens should be preserved.
        expect(result[1].type, TokenType.openTag);
        expect(result[2].type, TokenType.identifier);
        expect(result[2].value, 'user');
        expect(result[3].type, TokenType.dot);
        expect(result[4].type, TokenType.identifier);
        expect(result[4].value, 'name');
        expect(result[5].type, TokenType.openParenthesis);
        expect(result[6].type, TokenType.closeParenthesis);
        expect(result[7].type, TokenType.closeTag);
      });

      test('does not modify input list', () {
        final input = [
          testToken(TokenType.text, 'hello   '),
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          testToken(TokenType.closeTag, '}}'),
          testToken(TokenType.endOfFile, ''),
        ];

        final inputCopy = List.of(input);
        // ignore: unused_result
        WhitespaceProcessor.process(input);

        // Original input should be unchanged.
        expect(input, equals(inputCopy));
      });

      test('returns plain Tokens without whitespace control flags', () {
        final input = [
          const TokenWithWhitespaceControl(
            TokenType.openTag,
            '{{',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.identifier, 'name'),
          const TokenWithWhitespaceControl(
            TokenType.closeTag,
            '}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
        ];

        final result = WhitespaceProcessor.process(input);

        // All returned tokens should be plain Token instances,
        // not TokenWithWhitespaceControl.
        for (final token in result) {
          expect(token, isA<Token>());
          expect(token, isNot(isA<TokenWithWhitespaceControl>()));
        }

        // Verify the tokens are still correct after stripping flags.
        expect(result.length, 3);
        expect(result[0].type, TokenType.openTag);
        expect(result[0].value, '{{');
        expect(result[1].type, TokenType.identifier);
        expect(result[2].type, TokenType.closeTag);
      });

      test('integration: parser receives only plain Tokens', () {
        // This test verifies that the parser (and all downstream code)
        // never sees TokenWithWhitespaceControl instances.
        final scanner = Scanner('hello   {{- name -}}   world');
        final rawTokens = scanner.scan();

        // Scanner may emit TokenWithWhitespaceControl instances.
        var hasWhitespaceControlTokens = false;
        for (final token in rawTokens) {
          if (token is TokenWithWhitespaceControl) {
            hasWhitespaceControlTokens = true;
            break;
          }
        }
        expect(
          hasWhitespaceControlTokens,
          isTrue,
          reason: 'Scanner should emit TokenWithWhitespaceControl',
        );

        // After processing, all tokens should be plain Token instances.
        final processedTokens = WhitespaceProcessor.process(rawTokens);
        for (final token in processedTokens) {
          expect(token, isA<Token>());
          expect(
            token,
            isNot(isA<TokenWithWhitespaceControl>()),
            reason: 'Processed tokens should not have whitespace flags',
          );
        }

        // Verify the Parser constructor uses the processor,
        // so it never sees whitespace control flags.
        final parser = Parser('hello   {{- name -}}   world');
        // If this doesn't throw, the parser successfully processed
        // the tokens without needing to know about whitespace flags.
        final ast = parser.parse();
        expect(ast, isNotNull);
      });
    });

    group('Comment whitespace control', () {
      test('trims whitespace before comment with {{#-', () {
        final input = [
          testToken(TokenType.text, 'hello   '),
          const TokenWithWhitespaceControl(
            TokenType.openComment,
            '{{#',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.closeComment, '#}}'),
          testToken(TokenType.text, ' world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].type, TokenType.text);
        expect(result[0].value, 'hello');
        expect(result[1].type, TokenType.openComment);
        expect(result[2].type, TokenType.closeComment);
      });

      test('trims whitespace after comment with -#}}', () {
        final input = [
          testToken(TokenType.text, 'hello '),
          testToken(TokenType.openComment, '{{#'),
          const TokenWithWhitespaceControl(
            TokenType.closeComment,
            '#}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].value, 'hello ');
        expect(result[3].type, TokenType.text);
        expect(result[3].value, 'world');
      });

      test('trims whitespace on both sides with {{#- -#}}', () {
        final input = [
          testToken(TokenType.text, 'hello   '),
          const TokenWithWhitespaceControl(
            TokenType.openComment,
            '{{#',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          const TokenWithWhitespaceControl(
            TokenType.closeComment,
            '#}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].type, TokenType.text);
        expect(result[0].value, 'hello');
        expect(result[3].type, TokenType.text);
        expect(result[3].value, 'world');
      });

      test('removes text token if only whitespace remains after trimming', () {
        final input = [
          testToken(TokenType.text, '   '),
          const TokenWithWhitespaceControl(
            TokenType.openComment,
            '{{#',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          testToken(TokenType.closeComment, '#}}'),
          testToken(TokenType.text, 'world'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        // Text token with only whitespace should be removed.
        expect(result[0].type, TokenType.openComment);
        expect(result[2].type, TokenType.text);
        expect(result[2].value, 'world');
      });

      test('handles multiple comments with whitespace control', () {
        final input = [
          testToken(TokenType.text, 'A   '),
          const TokenWithWhitespaceControl(
            TokenType.openComment,
            '{{#',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          const TokenWithWhitespaceControl(
            TokenType.closeComment,
            '#}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   B   '),
          const TokenWithWhitespaceControl(
            TokenType.openComment,
            '{{#',
            placeholderLocation,
            trimWhitespaceBefore: true,
          ),
          const TokenWithWhitespaceControl(
            TokenType.closeComment,
            '#}}',
            placeholderLocation,
            trimWhitespaceAfter: true,
          ),
          testToken(TokenType.text, '   C'),
          testToken(TokenType.endOfFile, ''),
        ];

        final result = WhitespaceProcessor.process(input);

        expect(result[0].type, TokenType.text);
        expect(result[0].value, 'A');
        expect(result[3].type, TokenType.text);
        expect(result[3].value, 'B');
        expect(result[6].type, TokenType.text);
        expect(result[6].value, 'C');
      });
    });
  });
}
