import 'package:silhouette/src/scanner.dart';
import 'package:silhouette/src/token.dart';
import 'package:silhouette/src/whitespace_processor.dart';
import 'package:test/test.dart';

void main() {
  group('Scanner', () {
    test('scans plain text', () {
      final scanner = Scanner('Hello World');
      final tokens = scanner.scan();

      expect(tokens.length, 2);
      expect(tokens[0].type, TokenType.text);
      expect(tokens[0].value, 'Hello World');
      expect(tokens[1].type, TokenType.endOfFile);
    });

    test('scans simple tag with identifier', () {
      final scanner = Scanner('{{ name }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'name');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans text with embedded tags', () {
      final scanner = Scanner('Hello {{ name }}, welcome!');
      final tokens = scanner.scan();

      expect(tokens.length, 6);
      expect(tokens[0].type, TokenType.text);
      expect(tokens[0].value, 'Hello ');
      expect(tokens[1].type, TokenType.openTag);
      expect(tokens[2].type, TokenType.identifier);
      expect(tokens[2].value, 'name');
      expect(tokens[3].type, TokenType.closeTag);
      expect(tokens[4].type, TokenType.text);
      expect(tokens[4].value, ', welcome!');
      expect(tokens[5].type, TokenType.endOfFile);
    });

    test('scans tags with whitespace trimming', () {
      final scanner = Scanner('Hello   {{- name -}}   world');
      final rawTokens = scanner.scan();
      final tokens = WhitespaceProcessor.process(rawTokens);

      expect(tokens.length, 6);
      expect(tokens[0].type, TokenType.text);
      expect(tokens[0].value, 'Hello');
      expect(tokens[1].type, TokenType.openTag);
      expect(tokens[2].type, TokenType.identifier);
      expect(tokens[2].value, 'name');
      expect(tokens[3].type, TokenType.closeTag);
      expect(tokens[4].type, TokenType.text);
      expect(tokens[4].value, 'world');
      expect(tokens[5].type, TokenType.endOfFile);
    });

    test('scans string literals', () {
      final scanner = Scanner('{{ "Hello World" }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.stringLiteral);
      expect(tokens[1].value, 'Hello World');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans string literals with single quotes', () {
      final scanner = Scanner("{{ 'Hello World' }}");
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.stringLiteral);
      expect(tokens[1].value, 'Hello World');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans escaped strings', () {
      final scanner = Scanner(r'{{ "Hello\nWorld\t\"quoted\"" }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.stringLiteral);
      expect(tokens[1].value, 'Hello\nWorld\t"quoted"');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans number literals', () {
      final scanner = Scanner('{{ 42 }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].value, '42');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans decimal numbers', () {
      final scanner = Scanner('{{ 3.14159 }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].value, '3.14159');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans negative integer literals', () {
      final scanner = Scanner('{{ -42 }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].value, '-42');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans negative decimal literals', () {
      final scanner = Scanner('{{ -3.14159 }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].value, '-3.14159');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans negative zero', () {
      final scanner = Scanner('{{ -0 }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].value, '-0');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans minus operator with spaces', () {
      final scanner = Scanner('{{ 5 - 3 }}');
      final tokens = scanner.scan();

      expect(tokens.length, 6);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.numberLiteral);
      expect(tokens[1].value, '5');
      expect(tokens[2].type, TokenType.minus);
      expect(tokens[3].type, TokenType.numberLiteral);
      expect(tokens[3].value, '3');
      expect(tokens[4].type, TokenType.closeTag);
      expect(tokens[5].type, TokenType.endOfFile);
    });

    test('scans boolean literals', () {
      final scanner = Scanner('{{ true false }}');
      final tokens = scanner.scan();

      expect(tokens.length, 5);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.trueKeyword);
      expect(tokens[1].value, 'true');
      expect(tokens[2].type, TokenType.falseKeyword);
      expect(tokens[2].value, 'false');
      expect(tokens[3].type, TokenType.closeTag);
      expect(tokens[4].type, TokenType.endOfFile);
    });

    test('scans null literal', () {
      final scanner = Scanner('{{ null }}');
      final tokens = scanner.scan();

      expect(tokens.length, 4);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.nullKeyword);
      expect(tokens[1].value, 'null');
      expect(tokens[2].type, TokenType.closeTag);
      expect(tokens[3].type, TokenType.endOfFile);
    });

    test('scans reserved keywords', () {
      final scanner = Scanner('{{ if else for let set in include render }}');
      final tokens = scanner.scan();

      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.reservedKeyword);
      expect(tokens[1].value, 'if');
      expect(tokens[2].type, TokenType.reservedKeyword);
      expect(tokens[2].value, 'else');
      expect(tokens[3].type, TokenType.reservedKeyword);
      expect(tokens[3].value, 'for');
      expect(tokens[4].type, TokenType.reservedKeyword);
      expect(tokens[4].value, 'let');
      expect(tokens[5].type, TokenType.reservedKeyword);
      expect(tokens[5].value, 'set');
      expect(tokens[6].type, TokenType.reservedKeyword);
      expect(tokens[6].value, 'in');
      expect(tokens[7].type, TokenType.reservedKeyword);
      expect(tokens[7].value, 'include');
      expect(tokens[8].type, TokenType.reservedKeyword);
      expect(tokens[8].value, 'render');
      expect(tokens[9].type, TokenType.closeTag);
      expect(tokens[10].type, TokenType.endOfFile);
    });

    test('scans method calls', () {
      final scanner = Scanner("{{ myValue.toLowerCase().contains('Hello') }}");
      final tokens = scanner.scan();

      expect(tokens.length, 13);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'myValue');
      expect(tokens[2].type, TokenType.dot);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'toLowerCase');
      expect(tokens[4].type, TokenType.openParenthesis);
      expect(tokens[5].type, TokenType.closeParenthesis);
      expect(tokens[6].type, TokenType.dot);
      expect(tokens[7].type, TokenType.identifier);
      expect(tokens[7].value, 'contains');
      expect(tokens[8].type, TokenType.openParenthesis);
      expect(tokens[9].type, TokenType.stringLiteral);
      expect(tokens[9].value, 'Hello');
      expect(tokens[10].type, TokenType.closeParenthesis);
      expect(tokens[11].type, TokenType.closeTag);
      expect(tokens[12].type, TokenType.endOfFile);
    });

    test('scans function with multiple arguments', () {
      final scanner = Scanner('{{ format(name, age, 42.5) }}');
      final tokens = scanner.scan();

      expect(tokens.length, 11);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'format');
      expect(tokens[2].type, TokenType.openParenthesis);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'name');
      expect(tokens[4].type, TokenType.comma);
      expect(tokens[5].type, TokenType.identifier);
      expect(tokens[5].value, 'age');
      expect(tokens[6].type, TokenType.comma);
      expect(tokens[7].type, TokenType.numberLiteral);
      expect(tokens[7].value, '42.5');
      expect(tokens[8].type, TokenType.closeParenthesis);
      expect(tokens[9].type, TokenType.closeTag);
      expect(tokens[10].type, TokenType.endOfFile);
    });

    test('scans function with named arguments', () {
      final scanner = Scanner(
        '{{ format(date, pattern: "YYYY-MM-DD", locale: "en") }}',
      );
      final tokens = scanner.scan();

      expect(tokens.length, 15);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'format');
      expect(tokens[2].type, TokenType.openParenthesis);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'date');
      expect(tokens[4].type, TokenType.comma);
      expect(tokens[5].type, TokenType.identifier);
      expect(tokens[5].value, 'pattern');
      expect(tokens[6].type, TokenType.colon);
      expect(tokens[7].type, TokenType.stringLiteral);
      expect(tokens[7].value, 'YYYY-MM-DD');
      expect(tokens[8].type, TokenType.comma);
      expect(tokens[9].type, TokenType.identifier);
      expect(tokens[9].value, 'locale');
      expect(tokens[10].type, TokenType.colon);
      expect(tokens[11].type, TokenType.stringLiteral);
      expect(tokens[11].value, 'en');
      expect(tokens[12].type, TokenType.closeParenthesis);
      expect(tokens[13].type, TokenType.closeTag);
      expect(tokens[14].type, TokenType.endOfFile);
    });

    test('scans function with only named arguments', () {
      final scanner = Scanner(
        '{{ createUser(name: "John", age: 30, active: true) }}',
      );
      final tokens = scanner.scan();

      expect(tokens.length, 17);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'createUser');
      expect(tokens[2].type, TokenType.openParenthesis);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'name');
      expect(tokens[4].type, TokenType.colon);
      expect(tokens[5].type, TokenType.stringLiteral);
      expect(tokens[5].value, 'John');
      expect(tokens[6].type, TokenType.comma);
      expect(tokens[7].type, TokenType.identifier);
      expect(tokens[7].value, 'age');
      expect(tokens[8].type, TokenType.colon);
      expect(tokens[9].type, TokenType.numberLiteral);
      expect(tokens[9].value, '30');
      expect(tokens[10].type, TokenType.comma);
      expect(tokens[11].type, TokenType.identifier);
      expect(tokens[11].value, 'active');
      expect(tokens[12].type, TokenType.colon);
      expect(tokens[13].type, TokenType.trueKeyword);
      expect(tokens[13].value, 'true');
      expect(tokens[14].type, TokenType.closeParenthesis);
      expect(tokens[15].type, TokenType.closeTag);
      expect(tokens[16].type, TokenType.endOfFile);
    });

    test('scans complex named argument expressions', () {
      final scanner = Scanner(
        '{{ generate(template: user.getTemplate(), '
        'data: getData().items[0]) }}',
      );
      final tokens = scanner.scan();

      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'generate');
      expect(tokens[2].type, TokenType.openParenthesis);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'template');
      expect(tokens[4].type, TokenType.colon);
      expect(tokens[5].type, TokenType.identifier);
      expect(tokens[5].value, 'user');
      expect(tokens[6].type, TokenType.dot);
      expect(tokens[7].type, TokenType.identifier);
      expect(tokens[7].value, 'getTemplate');
      expect(tokens[8].type, TokenType.openParenthesis);
      expect(tokens[9].type, TokenType.closeParenthesis);
      expect(tokens[10].type, TokenType.comma);
      expect(tokens[11].type, TokenType.identifier);
      expect(tokens[11].value, 'data');
      expect(tokens[12].type, TokenType.colon);
    });

    test('scans mixed positional and named arguments in any order', () {
      final scanner = Scanner('{{ func(name: "John", 30, age: 25, "test") }}');
      final tokens = scanner.scan();

      expect(tokens.length, 17);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'func');
      expect(tokens[2].type, TokenType.openParenthesis);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'name');
      expect(tokens[4].type, TokenType.colon);
      expect(tokens[5].type, TokenType.stringLiteral);
      expect(tokens[5].value, 'John');
      expect(tokens[6].type, TokenType.comma);
      expect(tokens[7].type, TokenType.numberLiteral);
      expect(tokens[7].value, '30');
      expect(tokens[8].type, TokenType.comma);
      expect(tokens[9].type, TokenType.identifier);
      expect(tokens[9].value, 'age');
      expect(tokens[10].type, TokenType.colon);
      expect(tokens[11].type, TokenType.numberLiteral);
      expect(tokens[11].value, '25');
      expect(tokens[12].type, TokenType.comma);
      expect(tokens[13].type, TokenType.stringLiteral);
      expect(tokens[13].value, 'test');
      expect(tokens[14].type, TokenType.closeParenthesis);
      expect(tokens[15].type, TokenType.closeTag);
      expect(tokens[16].type, TokenType.endOfFile);
    });

    test('scans nested function calls with named arguments', () {
      final scanner = Scanner('{{ outer(inner(value: 42), name: "test") }}');
      final tokens = scanner.scan();

      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'outer');
      expect(tokens[2].type, TokenType.openParenthesis);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'inner');
      expect(tokens[4].type, TokenType.openParenthesis);
      expect(tokens[5].type, TokenType.identifier);
      expect(tokens[5].value, 'value');
      expect(tokens[6].type, TokenType.colon);
      expect(tokens[7].type, TokenType.numberLiteral);
      expect(tokens[7].value, '42');
      expect(tokens[8].type, TokenType.closeParenthesis);
      expect(tokens[9].type, TokenType.comma);
      expect(tokens[10].type, TokenType.identifier);
      expect(tokens[10].value, 'name');
      expect(tokens[11].type, TokenType.colon);
      expect(tokens[12].type, TokenType.stringLiteral);
      expect(tokens[12].value, 'test');
      expect(tokens[13].type, TokenType.closeParenthesis);
      expect(tokens[14].type, TokenType.closeTag);
      expect(tokens[15].type, TokenType.endOfFile);
    });

    test('scans named arguments with boolean and null values', () {
      final scanner = Scanner(
        '{{ config(enabled: true, disabled: false, value: null) }}',
      );
      final tokens = scanner.scan();

      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'config');
      expect(tokens[2].type, TokenType.openParenthesis);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'enabled');
      expect(tokens[4].type, TokenType.colon);
      expect(tokens[5].type, TokenType.trueKeyword);
      expect(tokens[6].type, TokenType.comma);
      expect(tokens[7].type, TokenType.identifier);
      expect(tokens[7].value, 'disabled');
      expect(tokens[8].type, TokenType.colon);
      expect(tokens[9].type, TokenType.falseKeyword);
      expect(tokens[10].type, TokenType.comma);
      expect(tokens[11].type, TokenType.identifier);
      expect(tokens[11].value, 'value');
      expect(tokens[12].type, TokenType.colon);
      expect(tokens[13].type, TokenType.nullKeyword);
      expect(tokens[14].type, TokenType.closeParenthesis);
      expect(tokens[15].type, TokenType.closeTag);
      expect(tokens[16].type, TokenType.endOfFile);
    });

    test('scans operators', () {
      final scanner = Scanner('{{ path/to/file : key-value }}');
      final tokens = scanner.scan();

      expect(tokens.length, 12);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'path');
      expect(tokens[2].type, TokenType.slash);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'to');
      expect(tokens[4].type, TokenType.slash);
      expect(tokens[5].type, TokenType.identifier);
      expect(tokens[5].value, 'file');
      expect(tokens[6].type, TokenType.colon);
      expect(tokens[7].type, TokenType.identifier);
      expect(tokens[7].value, 'key');
      expect(tokens[8].type, TokenType.minus);
      expect(tokens[9].type, TokenType.identifier);
      expect(tokens[9].value, 'value');
      expect(tokens[10].type, TokenType.closeTag);
      expect(tokens[11].type, TokenType.endOfFile);
    });

    test('scans multiple tags in text', () {
      final scanner = Scanner('''
Hello {{ name }}!
{% if logged_in %}
  Welcome back, {{ username }}.
{% else %}
  Please log in.
{% endif %}
''');

      final tokens = scanner.scan();

      // Find all the tag-related tokens.
      final tagTokens = tokens
          .where(
            (t) =>
                t.type == TokenType.openTag ||
                t.type == TokenType.closeTag ||
                t.type == TokenType.identifier,
          )
          .toList();

      // Expect 6 tokens: 2 open tags, 2 close tags, 2 identifiers.
      expect(tagTokens.length, 6);
    });

    test('preserves newlines in text', () {
      final scanner = Scanner('Line 1\nLine 2\r\nLine 3');
      final tokens = scanner.scan();

      expect(tokens.length, 2);
      expect(tokens[0].type, TokenType.text);
      expect(tokens[0].value, 'Line 1\nLine 2\r\nLine 3');
      expect(tokens[1].type, TokenType.endOfFile);
    });

    test('handles empty tags', () {
      final scanner = Scanner('{{}}');
      final tokens = scanner.scan();

      expect(tokens.length, 3);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.closeTag);
      expect(tokens[2].type, TokenType.endOfFile);
    });

    test('handles complex expressions', () {
      final scanner = Scanner(
        '{{ for item in items }}{{ item.name }}: {{ item.price }}{{ /for }}',
      );
      final tokens = scanner.scan();

      // Verify we get proper tokens for the for loop.
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.reservedKeyword);
      expect(tokens[1].value, 'for');
      expect(tokens[2].type, TokenType.identifier);
      expect(tokens[2].value, 'item');
      expect(tokens[3].type, TokenType.reservedKeyword);
      expect(tokens[3].value, 'in');
      expect(tokens[4].type, TokenType.identifier);
      expect(tokens[4].value, 'items');
      expect(tokens[5].type, TokenType.closeTag);
    });

    test('scans list index operations', () {
      final scanner = Scanner('{{ myList[3] }}');
      final tokens = scanner.scan();

      expect(tokens.length, 7);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'myList');
      expect(tokens[2].type, TokenType.openSquareBracket);
      expect(tokens[3].type, TokenType.numberLiteral);
      expect(tokens[3].value, '3');
      expect(tokens[4].type, TokenType.closeSquareBracket);
      expect(tokens[5].type, TokenType.closeTag);
      expect(tokens[6].type, TokenType.endOfFile);
    });

    test('scans map index operations with string keys', () {
      final scanner = Scanner("{{ myMap['key'] }}");
      final tokens = scanner.scan();

      expect(tokens.length, 7);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'myMap');
      expect(tokens[2].type, TokenType.openSquareBracket);
      expect(tokens[3].type, TokenType.stringLiteral);
      expect(tokens[3].value, 'key');
      expect(tokens[4].type, TokenType.closeSquareBracket);
      expect(tokens[5].type, TokenType.closeTag);
      expect(tokens[6].type, TokenType.endOfFile);
    });

    test('scans index operations with identifiers', () {
      final scanner = Scanner('{{ array[index] }}');
      final tokens = scanner.scan();

      expect(tokens.length, 7);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'array');
      expect(tokens[2].type, TokenType.openSquareBracket);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'index');
      expect(tokens[4].type, TokenType.closeSquareBracket);
      expect(tokens[5].type, TokenType.closeTag);
      expect(tokens[6].type, TokenType.endOfFile);
    });

    test('scans nested index operations', () {
      final scanner = Scanner("{{ data['users'][0]['name'] }}");
      final tokens = scanner.scan();

      expect(tokens.length, 13);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'data');
      expect(tokens[2].type, TokenType.openSquareBracket);
      expect(tokens[3].type, TokenType.stringLiteral);
      expect(tokens[3].value, 'users');
      expect(tokens[4].type, TokenType.closeSquareBracket);
      expect(tokens[5].type, TokenType.openSquareBracket);
      expect(tokens[6].type, TokenType.numberLiteral);
      expect(tokens[6].value, '0');
      expect(tokens[7].type, TokenType.closeSquareBracket);
      expect(tokens[8].type, TokenType.openSquareBracket);
      expect(tokens[9].type, TokenType.stringLiteral);
      expect(tokens[9].value, 'name');
      expect(tokens[10].type, TokenType.closeSquareBracket);
      expect(tokens[11].type, TokenType.closeTag);
      expect(tokens[12].type, TokenType.endOfFile);
    });

    test('scans mixed property and index access', () {
      final scanner = Scanner('{{ user.addresses[0].city }}');
      final tokens = scanner.scan();

      expect(tokens.length, 11);
      expect(tokens[0].type, TokenType.openTag);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].value, 'user');
      expect(tokens[2].type, TokenType.dot);
      expect(tokens[3].type, TokenType.identifier);
      expect(tokens[3].value, 'addresses');
      expect(tokens[4].type, TokenType.openSquareBracket);
      expect(tokens[5].type, TokenType.numberLiteral);
      expect(tokens[5].value, '0');
      expect(tokens[6].type, TokenType.closeSquareBracket);
      expect(tokens[7].type, TokenType.dot);
      expect(tokens[8].type, TokenType.identifier);
      expect(tokens[8].value, 'city');
      expect(tokens[9].type, TokenType.closeTag);
      expect(tokens[10].type, TokenType.endOfFile);
    });

    group('Comments', () {
      test('scans and emits comment tokens', () {
        final scanner = Scanner('Hello {{# This is a comment #}} World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment at start of template', () {
        final scanner = Scanner('{{# Header comment #}}Hello');
        final tokens = scanner.scan();

        expect(tokens.length, 4);
        expect(tokens[0].type, TokenType.openComment);
        expect(tokens[1].type, TokenType.closeComment);
        expect(tokens[2].type, TokenType.text);
        expect(tokens[2].value, 'Hello');
        expect(tokens[3].type, TokenType.endOfFile);
      });

      test('scans comment at end of template', () {
        final scanner = Scanner('Hello{{# Footer comment #}}');
        final tokens = scanner.scan();

        expect(tokens.length, 4);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.endOfFile);
      });

      test('scans multiple comments', () {
        final scanner = Scanner(
          'Start {{# comment 1 #}} middle {{# comment 2 #}} end',
        );
        final tokens = scanner.scan();

        expect(tokens.length, 8);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Start ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' middle ');
        expect(tokens[4].type, TokenType.openComment);
        expect(tokens[5].type, TokenType.closeComment);
        expect(tokens[6].type, TokenType.text);
        expect(tokens[6].value, ' end');
        expect(tokens[7].type, TokenType.endOfFile);
      });

      test('scans empty comment', () {
        final scanner = Scanner('Hello {{##}} World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment with special characters', () {
        final scanner = Scanner('Hello {{# {{ }} {{ name }} #}} World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment with newlines', () {
        final scanner = Scanner(
          'Hello {{# This is a\nmulti-line\ncomment #}} World',
        );
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment between tags', () {
        final scanner = Scanner('{{ name }}{{# comment #}}{{ age }}');
        final tokens = scanner.scan();

        expect(tokens[0].type, TokenType.openTag);
        expect(tokens[1].type, TokenType.identifier);
        expect(tokens[1].value, 'name');
        expect(tokens[2].type, TokenType.closeTag);
        expect(tokens[3].type, TokenType.openComment);
        expect(tokens[4].type, TokenType.closeComment);
        expect(tokens[5].type, TokenType.openTag);
        expect(tokens[6].type, TokenType.identifier);
        expect(tokens[6].value, 'age');
        expect(tokens[7].type, TokenType.closeTag);
        expect(tokens[8].type, TokenType.endOfFile);
      });

      test('scans comment with trim before', () {
        final scanner = Scanner('Hello   {{#- comment #}} World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello   ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[1], isA<TokenWithWhitespaceControl>());
        expect(
          (tokens[1] as TokenWithWhitespaceControl).trimWhitespaceBefore,
          true,
        );
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment with trim after', () {
        final scanner = Scanner('Hello {{# comment -#}}   World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[2], isA<TokenWithWhitespaceControl>());
        expect(
          (tokens[2] as TokenWithWhitespaceControl).trimWhitespaceAfter,
          true,
        );
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '   World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment with trim both sides', () {
        final scanner = Scanner('Hello   {{#- comment -#}}   World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello   ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[1], isA<TokenWithWhitespaceControl>());
        expect(
          (tokens[1] as TokenWithWhitespaceControl).trimWhitespaceBefore,
          true,
        );
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[2], isA<TokenWithWhitespaceControl>());
        expect(
          (tokens[2] as TokenWithWhitespaceControl).trimWhitespaceAfter,
          true,
        );
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '   World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment trim with only whitespace before', () {
        final scanner = Scanner('   {{#- comment #}} World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, '   ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment trim with only whitespace after', () {
        final scanner = Scanner('Hello {{# comment -#}}   ');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '   ');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment trim with tabs and newlines', () {
        final scanner = Scanner('Hello\n\t  {{#- comment -#}}  \t\nWorld');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello\n\t  ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '  \t\nWorld');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans multiple comments with whitespace control', () {
        final scanner = Scanner(
          'A   {{#- c1 -#}}   B   {{#- c2 -#}}   C',
        );
        final tokens = scanner.scan();

        expect(tokens.length, 8);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'A   ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '   B   ');
        expect(tokens[4].type, TokenType.openComment);
        expect(tokens[5].type, TokenType.closeComment);
        expect(tokens[6].type, TokenType.text);
        expect(tokens[6].value, '   C');
        expect(tokens[7].type, TokenType.endOfFile);
      });

      test('scans comment with whitespace control around tags', () {
        final scanner = Scanner('Hello   {{#- comment -#}}   {{ name }}');
        final tokens = scanner.scan();

        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello   ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '   ');
        expect(tokens[4].type, TokenType.openTag);
        expect(tokens[5].type, TokenType.identifier);
        expect(tokens[5].value, 'name');
        expect(tokens[6].type, TokenType.closeTag);
        expect(tokens[7].type, TokenType.endOfFile);
      });

      test('handles unclosed comment gracefully', () {
        final scanner = Scanner('Hello {{# unclosed comment');
        final tokens = scanner.scan();

        // Scanner should handle this gracefully without crashing.
        expect(tokens.last.type, TokenType.endOfFile);
      });

      test('scans comment that looks like tag inside', () {
        final scanner = Scanner(
          'Hello {{# This has {{ and }} inside #}} World',
        );
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('scans comment with hash symbols inside', () {
        final scanner = Scanner('Hello {{# #hashtag #another #}} World');
        final tokens = scanner.scan();

        expect(tokens.length, 5);
        expect(tokens[0].type, TokenType.text);
        expect(tokens[0].value, 'Hello ');
        expect(tokens[1].type, TokenType.openComment);
        expect(tokens[2].type, TokenType.closeComment);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' World');
        expect(tokens[4].type, TokenType.endOfFile);
      });

      test('distinguishes comments from tags', () {
        final scanner = Scanner('{{ name }} {{# comment #}} {{ age }}');
        final tokens = scanner.scan();

        expect(tokens[0].type, TokenType.openTag);
        expect(tokens[1].type, TokenType.identifier);
        expect(tokens[1].value, 'name');
        expect(tokens[2].type, TokenType.closeTag);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, ' ');
        expect(tokens[4].type, TokenType.openComment);
        expect(tokens[5].type, TokenType.closeComment);
        expect(tokens[6].type, TokenType.text);
        expect(tokens[6].value, ' ');
        expect(tokens[7].type, TokenType.openTag);
        expect(tokens[8].type, TokenType.identifier);
        expect(tokens[8].value, 'age');
        expect(tokens[9].type, TokenType.closeTag);
        expect(tokens[10].type, TokenType.endOfFile);
      });
    });
  });
}
