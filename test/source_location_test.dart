import 'package:silhouette/src/exceptions.dart';
import 'package:silhouette/src/parser.dart';
import 'package:silhouette/src/scanner.dart';
import 'package:silhouette/src/token.dart';
import 'package:test/test.dart';

void main() {
  group('SourceLocation', () {
    test('stores line, column, offset, and length', () {
      const location = SourceLocation(
        line: 5,
        column: 12,
        offset: 84,
        length: 8,
      );

      expect(location.line, 5);
      expect(location.column, 12);
      expect(location.offset, 84);
      expect(location.length, 8);
    });

    test('provides readable toString', () {
      const location = SourceLocation(
        line: 5,
        column: 12,
        offset: 84,
        length: 8,
      );

      expect(location.toString(), 'line 5, column 12');
    });

    test('supports equality comparison', () {
      const location1 = SourceLocation(
        line: 5,
        column: 12,
        offset: 84,
        length: 8,
      );
      const location2 = SourceLocation(
        line: 5,
        column: 12,
        offset: 84,
        length: 8,
      );
      const location3 = SourceLocation(
        line: 6,
        column: 12,
        offset: 84,
        length: 8,
      );

      expect(location1, equals(location2));
      expect(location1, isNot(equals(location3)));
    });

    test('works with hash-based collections', () {
      const location1 = SourceLocation(
        line: 5,
        column: 12,
        offset: 84,
        length: 8,
      );
      const location2 = SourceLocation(
        line: 5,
        column: 12,
        offset: 84,
        length: 8,
      );

      final set = {location1};
      expect(set.contains(location2), isTrue);
    });
  });

  group('Token with SourceLocation', () {
    test('includes location in token', () {
      const location = SourceLocation(
        line: 1,
        column: 4,
        offset: 3,
        length: 4,
      );
      const token = Token(TokenType.identifier, 'name', location);

      expect(token.location, equals(location));
      expect(token.location.line, 1);
      expect(token.location.column, 4);
    });

    test('toString includes location information', () {
      const location = SourceLocation(
        line: 1,
        column: 4,
        offset: 3,
        length: 4,
      );
      const token = Token(TokenType.identifier, 'name', location);

      final string = token.toString();
      expect(string, contains('identifier'));
      expect(string, contains('name'));
      expect(string, contains('line 1'));
      expect(string, contains('column 4'));
    });
  });

  group('Scanner location tracking', () {
    test('tracks location for single line text', () {
      final scanner = Scanner('Hello World');
      final tokens = scanner.scan();

      // Text token should start at line 1, column 1.
      expect(tokens[0].type, TokenType.text);
      expect(tokens[0].location.line, 1);
      expect(tokens[0].location.column, 1);
      expect(tokens[0].location.offset, 0);
      expect(tokens[0].location.length, 11);
    });

    test('tracks location for simple expression', () {
      final scanner = Scanner('{{ name }}');
      final tokens = scanner.scan();

      // {{ at line 1, column 1.
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[0].location.line, 1);
      expect(tokens[0].location.column, 1);
      expect(tokens[0].location.offset, 0);

      // name at line 1, column 4 (after '{{ ').
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].location.line, 1);
      expect(tokens[1].location.column, 4);
      expect(tokens[1].location.offset, 3);
      expect(tokens[1].location.length, 4);

      // }} at line 1, column 9.
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[2].location.line, 1);
      expect(tokens[2].location.column, 9);
      expect(tokens[2].location.offset, 8);
    });

    test('tracks line numbers across newlines', () {
      final scanner = Scanner('Hello\n{{ name }}');
      final tokens = scanner.scan();

      // Text on line 1.
      expect(tokens[0].type, TokenType.text);
      expect(tokens[0].location.line, 1);
      expect(tokens[0].location.column, 1);

      // {{ on line 2, column 1.
      expect(tokens[1].type, TokenType.openTag);
      expect(tokens[1].location.line, 2);
      expect(tokens[1].location.column, 1);

      // name on line 2, column 4.
      expect(tokens[2].type, TokenType.identifier);
      expect(tokens[2].location.line, 2);
      expect(tokens[2].location.column, 4);
    });

    test('tracks location for multi-line text token', () {
      final scanner = Scanner('Line 1\nLine 2\nLine 3');
      final tokens = scanner.scan();

      // Text token starts at line 1, column 1.
      expect(tokens[0].type, TokenType.text);
      expect(tokens[0].location.line, 1);
      expect(tokens[0].location.column, 1);
      expect(tokens[0].location.offset, 0);
      expect(tokens[0].location.length, 20); // Total length including newlines.
    });

    test('tracks location for string literals', () {
      final scanner = Scanner('{{ "hello world" }}');
      final tokens = scanner.scan();

      expect(tokens[1].type, TokenType.stringLiteral);
      expect(tokens[1].location.line, 1);
      expect(tokens[1].location.column, 4);
      expect(tokens[1].location.offset, 3);
      expect(tokens[1].location.length, 13); // Includes quotes.
    });

    test('tracks location for number literals', () {
      final scanner = Scanner('{{ 42 }}');
      final tokens = scanner.scan();

      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].location.line, 1);
      expect(tokens[1].location.column, 4);
      expect(tokens[1].location.offset, 3);
      expect(tokens[1].location.length, 2);
    });

    test('tracks location for negative number literals', () {
      final scanner = Scanner('{{ -42 }}');
      final tokens = scanner.scan();

      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].location.line, 1);
      expect(tokens[1].location.column, 4);
      expect(tokens[1].location.offset, 3);
      expect(tokens[1].location.length, 3); // Includes minus sign.
    });

    test('tracks location across multiple expressions', () {
      final scanner = Scanner('{{ a }}\n{{ b }}');
      final tokens = scanner.scan();

      // First expression on line 1.
      expect(tokens[0].location.line, 1); // {{
      expect(tokens[1].location.line, 1); // a
      expect(tokens[2].location.line, 1); // }}

      // Text (newline) between expressions.
      expect(tokens[3].type, TokenType.text);
      expect(tokens[3].location.line, 1);

      // Second expression on line 2.
      expect(tokens[4].location.line, 2); // {{
      expect(tokens[5].location.line, 2); // b
      expect(tokens[6].location.line, 2); // }}
    });

    test('tracks location for complex expression', () {
      final scanner = Scanner('{{ user.name }}');
      final tokens = scanner.scan();

      // user at column 4.
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'user');
      expect(tokens[1].location.column, 4);

      // . at column 8.
      expect(tokens[2].type, TokenType.dot);
      expect(tokens[2].location.column, 8);

      // name at column 9.
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'name');
      expect(tokens[3].location.column, 9);
    });
  });

  group('ParseException with location', () {
    test('includes location in error message', () {
      try {
        final parser = Parser('{{ invalid syntax');
        // ignore: unused_result
        parser.parse();
        fail('Expected ParseException');
      } on ParseException catch (e) {
        final message = e.toString();
        expect(message, contains('ParseException'));
        expect(message, contains('line'));
        expect(message, contains('column'));
      }
    });

    test('shows token information in error', () {
      try {
        final parser = Parser('{{ invalid syntax');
        // ignore: unused_result
        parser.parse();
        fail('Expected ParseException');
      } on ParseException catch (e) {
        expect(e.token, isNotNull);
        expect(e.token!.location, isNotNull);

        final message = e.toString();
        expect(message, contains('token:'));
      }
    });
  });

  group('End-to-end location tracking', () {
    test('maintains location through full pipeline', () {
      const template = 'Hello {{ name }}!';
      final scanner = Scanner(template);
      final tokens = scanner.scan();

      // Verify scanner produced tokens with locations.
      for (final token in tokens) {
        expect(token.location, isNotNull);
        expect(token.location.line, greaterThan(0));
        expect(token.location.column, greaterThan(0));
        expect(token.location.offset, greaterThanOrEqualTo(0));
      }

      // Verify parser can consume tokens with locations.
      final parser = Parser(template);
      final ast = parser.parse();
      expect(ast, isNotNull);
    });

    test('locations remain accurate after whitespace processing', () {
      const template = 'Hello   {{- name -}}   World';
      final scanner = Scanner(template);
      final rawTokens = scanner.scan();

      // All raw tokens should have locations.
      for (final token in rawTokens) {
        expect(token.location, isNotNull);
      }

      // After processing, locations should still be present.
      final parser = Parser(template);
      final ast = parser.parse();
      expect(ast, isNotNull);
    });

    test('location tracking works with multi-line templates', () {
      const template = 'Line 1: {{ a }}\nLine 2: {{ b }}\nLine 3: {{ c }}';

      final scanner = Scanner(template);
      final tokens = scanner.scan();

      // Find identifier tokens and verify they're on different lines.
      final identifiers = tokens
          .where((t) => t.type == TokenType.identifier)
          .toList();

      expect(identifiers.length, 3);
      expect(identifiers[0].value, 'a');
      expect(identifiers[0].location.line, 1);

      expect(identifiers[1].value, 'b');
      expect(identifiers[1].location.line, 2);

      expect(identifiers[2].value, 'c');
      expect(identifiers[2].location.line, 3);
    });
  });
}
