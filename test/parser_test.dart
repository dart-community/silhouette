import 'package:silhouette/src/ast.dart';
import 'package:silhouette/src/exceptions.dart';
import 'package:silhouette/src/parser.dart';
import 'package:silhouette/src/token.dart';
import 'package:test/test.dart';

void main() {
  group('Parser', () {
    group('Basic parsing', () {
      test('parses plain text', () {
        final parser = Parser('Hello World');
        final result = parser.parse();

        expect(result, isA<TextOutputStatement>());
        final textStmt = result as TextOutputStatement;
        expect(textStmt.text, 'Hello World');
      });

      test('parses empty input', () {
        final parser = Parser('');
        final result = parser.parse();

        expect(result, isA<OrderedStatements>());
        final ordered = result as OrderedStatements;
        expect(ordered.statements, isEmpty);
      });

      test('parses empty tags', () {
        final parser = Parser('{{}}');
        final result = parser.parse();

        expect(result, isA<TextOutputStatement>());
        final textStmt = result as TextOutputStatement;
        expect(textStmt.text, '');
      });

      test('parses multiple text segments', () {
        final parser = Parser('Hello {{ name }}, welcome!');
        final result = parser.parse();

        expect(result, isA<OrderedStatements>());
        final ordered = result as OrderedStatements;
        expect(ordered.statements.length, 3);

        expect(ordered.statements[0], isA<TextOutputStatement>());
        expect((ordered.statements[0] as TextOutputStatement).text, 'Hello ');

        expect(ordered.statements[1], isA<ExpressionOutputStatement>());

        expect(ordered.statements[2], isA<TextOutputStatement>());
        expect(
          (ordered.statements[2] as TextOutputStatement).text,
          ', welcome!',
        );
      });
    });

    group('Identifier expressions', () {
      test('parses simple identifier', () {
        final parser = Parser('{{ name }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<IdentifierExpression>());
        final identifier = exprStmt.expression as IdentifierExpression;
        expect(identifier.token.value, 'name');
      });

      test('parses identifier with underscores', () {
        final parser = Parser('{{ user_name }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<IdentifierExpression>());
        final identifier = exprStmt.expression as IdentifierExpression;
        expect(identifier.token.value, 'user_name');
      });
    });

    group('Literal expressions', () {
      test('parses string literal with double quotes', () {
        final parser = Parser('{{ "Hello World" }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, 'Hello World');
        expect(literal.token.type, TokenType.stringLiteral);
      });

      test('parses string literal with single quotes', () {
        final parser = Parser("{{ 'Hello World' }}");
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, 'Hello World');
      });

      test('parses integer literal', () {
        final parser = Parser('{{ 42 }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, 42);
        expect(literal.token.type, TokenType.numberLiteral);
      });

      test('parses decimal literal', () {
        final parser = Parser('{{ 3.14159 }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, 3.14159);
      });

      test('parses negative integer literal', () {
        final parser = Parser('{{ -42 }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, -42);
        expect(literal.token.type, TokenType.numberLiteral);
      });

      test('parses negative decimal literal', () {
        final parser = Parser('{{ -3.14 }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, -3.14);
        expect(literal.token.type, TokenType.numberLiteral);
      });

      test('parses negative zero', () {
        final parser = Parser('{{ -0 }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, -0);
        expect(literal.token.type, TokenType.numberLiteral);
      });

      test('parses boolean true', () {
        final parser = Parser('{{ true }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, true);
        expect(literal.token.type, TokenType.trueKeyword);
      });

      test('parses boolean false', () {
        final parser = Parser('{{ false }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, false);
        expect(literal.token.type, TokenType.falseKeyword);
      });

      test('parses null literal', () {
        final parser = Parser('{{ null }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<LiteralExpression>());
        final literal = exprStmt.expression as LiteralExpression;
        expect(literal.value, null);
        expect(literal.token.type, TokenType.nullKeyword);
      });
    });

    group('Property access', () {
      test('parses simple property access', () {
        final parser = Parser('{{ user.name }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<PropertyAccessExpression>());
        final propAccess = exprStmt.expression as PropertyAccessExpression;

        expect(propAccess.object, isA<IdentifierExpression>());
        expect((propAccess.object as IdentifierExpression).token.value, 'user');
        expect(propAccess.identifier.value, 'name');
      });

      test('parses chained property access', () {
        final parser = Parser('{{ user.profile.name }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<PropertyAccessExpression>());
        final outer = exprStmt.expression as PropertyAccessExpression;
        expect(outer.identifier.value, 'name');

        expect(outer.object, isA<PropertyAccessExpression>());
        final inner = outer.object as PropertyAccessExpression;
        expect(inner.identifier.value, 'profile');

        expect(inner.object, isA<IdentifierExpression>());
        expect((inner.object as IdentifierExpression).token.value, 'user');
      });
    });

    group('Index access', () {
      test('parses array index with number', () {
        final parser = Parser('{{ items[0] }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<IndexAccessExpression>());
        final indexAccess = exprStmt.expression as IndexAccessExpression;

        expect(indexAccess.object, isA<IdentifierExpression>());
        expect(
          (indexAccess.object as IdentifierExpression).token.value,
          'items',
        );

        expect(indexAccess.index, isA<LiteralExpression>());
        expect((indexAccess.index as LiteralExpression).value, 0);
      });

      test('parses map index with string', () {
        final parser = Parser("{{ config['database'] }}");
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<IndexAccessExpression>());
        final indexAccess = exprStmt.expression as IndexAccessExpression;

        expect(indexAccess.object, isA<IdentifierExpression>());
        expect(
          (indexAccess.object as IdentifierExpression).token.value,
          'config',
        );

        expect(indexAccess.index, isA<LiteralExpression>());
        expect((indexAccess.index as LiteralExpression).value, 'database');
      });

      test('parses index with identifier', () {
        final parser = Parser('{{ array[index] }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<IndexAccessExpression>());
        final indexAccess = exprStmt.expression as IndexAccessExpression;

        expect(indexAccess.index, isA<IdentifierExpression>());
        expect(
          (indexAccess.index as IdentifierExpression).token.value,
          'index',
        );
      });

      test('parses nested index access', () {
        final parser = Parser("{{ data['users'][0] }}");
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<IndexAccessExpression>());
        final outer = exprStmt.expression as IndexAccessExpression;
        expect((outer.index as LiteralExpression).value, 0);

        expect(outer.object, isA<IndexAccessExpression>());
        final inner = outer.object as IndexAccessExpression;
        expect((inner.index as LiteralExpression).value, 'users');
        expect((inner.object as IdentifierExpression).token.value, 'data');
      });
    });

    group('Function calls', () {
      test('parses function call with no arguments', () {
        final parser = Parser('{{ getName() }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.callee, isA<IdentifierExpression>());
        expect((call.callee as IdentifierExpression).token.value, 'getName');
        expect(call.positionalArguments, isEmpty);
        expect(call.namedArguments, isEmpty);
      });

      test('parses function call with single argument', () {
        final parser = Parser("{{ format('date') }}");
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.positionalArguments.length, 1);
        expect(call.positionalArguments[0], isA<LiteralExpression>());
        expect(
          (call.positionalArguments[0] as LiteralExpression).value,
          'date',
        );
        expect(call.namedArguments, isEmpty);
      });

      test('parses function call with multiple arguments', () {
        final parser = Parser('{{ substring(text, 0, 10) }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.positionalArguments.length, 3);
        expect(call.positionalArguments[0], isA<IdentifierExpression>());
        expect(call.positionalArguments[1], isA<LiteralExpression>());
        expect(call.positionalArguments[2], isA<LiteralExpression>());
        expect(call.namedArguments, isEmpty);
      });

      test('parses method call on property', () {
        final parser = Parser('{{ user.getName() }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.callee, isA<PropertyAccessExpression>());
        final prop = call.callee as PropertyAccessExpression;
        expect(prop.identifier.value, 'getName');
      });

      test('parses chained method calls', () {
        final parser = Parser('{{ text.trim().toUpperCase() }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final outer = exprStmt.expression as CallExpression;

        expect(outer.callee, isA<PropertyAccessExpression>());
        final outerProp = outer.callee as PropertyAccessExpression;
        expect(outerProp.identifier.value, 'toUpperCase');

        expect(outerProp.object, isA<CallExpression>());
        final inner = outerProp.object as CallExpression;

        expect(inner.callee, isA<PropertyAccessExpression>());
        final innerProp = inner.callee as PropertyAccessExpression;
        expect(innerProp.identifier.value, 'trim');
      });

      test('parses function call with only named arguments', () {
        final parser = Parser('{{ createUser(name: "John", age: 30) }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.positionalArguments, isEmpty);
        expect(call.namedArguments.length, 2);
        expect(call.namedArguments['name'], isA<LiteralExpression>());
        expect(
          (call.namedArguments['name'] as LiteralExpression).value,
          'John',
        );
        expect(call.namedArguments['age'], isA<LiteralExpression>());
        expect((call.namedArguments['age'] as LiteralExpression).value, 30);
      });

      test(
        'parses function call with mixed positional and named arguments',
        () {
          final parser = Parser(
            '{{ format(date, pattern: "YYYY-MM-DD", locale: "en") }}',
          );
          final result = parser.parse();

          expect(result, isA<ExpressionOutputStatement>());
          final exprStmt = result as ExpressionOutputStatement;

          expect(exprStmt.expression, isA<CallExpression>());
          final call = exprStmt.expression as CallExpression;

          expect(call.positionalArguments.length, 1);
          expect(call.positionalArguments[0], isA<IdentifierExpression>());
          expect(
            (call.positionalArguments[0] as IdentifierExpression).token.value,
            'date',
          );

          expect(call.namedArguments.length, 2);
          expect(call.namedArguments['pattern'], isA<LiteralExpression>());
          expect(
            (call.namedArguments['pattern'] as LiteralExpression).value,
            'YYYY-MM-DD',
          );
          expect(call.namedArguments['locale'], isA<LiteralExpression>());
          expect(
            (call.namedArguments['locale'] as LiteralExpression).value,
            'en',
          );
        },
      );

      test('parses named arguments with complex expressions', () {
        final parser = Parser(
          '{{ generate(template: user.getTemplate(), data: items[0]) }}',
        );
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.positionalArguments, isEmpty);
        expect(call.namedArguments.length, 2);

        expect(call.namedArguments['template'], isA<CallExpression>());
        final templateCall = call.namedArguments['template'] as CallExpression;
        expect(templateCall.callee, isA<PropertyAccessExpression>());

        expect(call.namedArguments['data'], isA<IndexAccessExpression>());
        final dataIndex = call.namedArguments['data'] as IndexAccessExpression;
        expect(dataIndex.object, isA<IdentifierExpression>());
      });

      test('parses mixed arguments in any order', () {
        final parser = Parser('{{ func(name: "John", 30, age: 25, "test") }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.positionalArguments.length, 2);
        expect((call.positionalArguments[0] as LiteralExpression).value, 30);
        expect(
          (call.positionalArguments[1] as LiteralExpression).value,
          'test',
        );

        expect(call.namedArguments.length, 2);
        expect(
          (call.namedArguments['name'] as LiteralExpression).value,
          'John',
        );
        expect((call.namedArguments['age'] as LiteralExpression).value, 25);
      });

      test('throws error for duplicate named arguments', () {
        expect(
          () => Parser('{{ func(name: "John", name: "Jane") }}').parse(),
          throwsA(
            isA<ParseException>().having(
              (e) => e.message,
              'message',
              'Duplicate named parameter: name',
            ),
          ),
        );
      });

      test('parses method call with named arguments', () {
        final parser = Parser('{{ user.format(pattern: "short") }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.callee, isA<PropertyAccessExpression>());
        final prop = call.callee as PropertyAccessExpression;
        expect(prop.identifier.value, 'format');

        expect(call.positionalArguments, isEmpty);
        expect(call.namedArguments.length, 1);
        expect(call.namedArguments['pattern'], isA<LiteralExpression>());
        expect(
          (call.namedArguments['pattern'] as LiteralExpression).value,
          'short',
        );
      });

      test('parses complex mixed argument ordering', () {
        final parser = Parser(
          '{{ process(data, type: "json", items[0], format: true, "output") }}',
        );
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.positionalArguments.length, 3);
        expect(call.positionalArguments[0], isA<IdentifierExpression>());
        expect(call.positionalArguments[1], isA<IndexAccessExpression>());
        expect(
          (call.positionalArguments[2] as LiteralExpression).value,
          'output',
        );

        expect(call.namedArguments.length, 2);
        expect(
          (call.namedArguments['type'] as LiteralExpression).value,
          'json',
        );
        expect(
          (call.namedArguments['format'] as LiteralExpression).value,
          true,
        );
      });
    });

    group('Complex expressions', () {
      test('parses mixed property and index access', () {
        final parser = Parser('{{ user.addresses[0].city }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<PropertyAccessExpression>());
        final prop = exprStmt.expression as PropertyAccessExpression;
        expect(prop.identifier.value, 'city');

        expect(prop.object, isA<IndexAccessExpression>());
        final index = prop.object as IndexAccessExpression;
        expect((index.index as LiteralExpression).value, 0);

        expect(index.object, isA<PropertyAccessExpression>());
      });

      test('parses method call with complex arguments', () {
        final parser = Parser("{{ format(user.name, config['format']) }}");
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.positionalArguments.length, 2);
        expect(call.positionalArguments[0], isA<PropertyAccessExpression>());
        expect(call.positionalArguments[1], isA<IndexAccessExpression>());
        expect(call.namedArguments, isEmpty);
      });

      test('parses grouped expressions', () {
        final parser = Parser('{{ (getValue()) }}');
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;
        expect((call.callee as IdentifierExpression).token.value, 'getValue');
      });

      test('parses deeply nested expression', () {
        final parser = Parser(
          "{{ users[0].profile.addresses[currentIndex].format('short') }}",
        );
        final result = parser.parse();

        expect(result, isA<ExpressionOutputStatement>());
        final exprStmt = result as ExpressionOutputStatement;

        expect(exprStmt.expression, isA<CallExpression>());
        final call = exprStmt.expression as CallExpression;

        expect(call.callee, isA<PropertyAccessExpression>());
        final formatProp = call.callee as PropertyAccessExpression;
        expect(formatProp.identifier.value, 'format');

        expect(formatProp.object, isA<IndexAccessExpression>());
      });
    });

    group('If statements', () {
      test('parses basic if statement', () {
        final parser = Parser('{{ if visible }}Hello{{ /if }}');
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        expect(ifStmt.condition, isA<IdentifierExpression>());
        expect(
          (ifStmt.condition as IdentifierExpression).token.value,
          'visible',
        );

        expect(ifStmt.body, isA<OrderedStatements>());
        final body = ifStmt.body as OrderedStatements;
        expect(body.statements.length, 1);
        expect(body.statements[0], isA<TextOutputStatement>());
        expect((body.statements[0] as TextOutputStatement).text, 'Hello');

        expect(ifStmt.elseBranch, isNull);
      });

      test('parses if-else statement', () {
        final parser = Parser('{{ if show }}yes{{ else }}no{{ /if }}');
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        final body = ifStmt.body as OrderedStatements;
        expect(body.statements.length, 1);
        expect((body.statements[0] as TextOutputStatement).text, 'yes');

        expect(ifStmt.elseBranch, isA<OrderedStatements>());
        final elseBranch = ifStmt.elseBranch! as OrderedStatements;
        expect(elseBranch.statements.length, 1);
        expect(
          (elseBranch.statements[0] as TextOutputStatement).text,
          'no',
        );
      });

      test('parses if-else if-else as nested IfStatements', () {
        final parser = Parser(
          '{{ if a }}1{{ else if b }}2{{ else }}3{{ /if }}',
        );
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        final body = ifStmt.body as OrderedStatements;
        expect((body.statements[0] as TextOutputStatement).text, '1');

        // An `else if` produces a nested `IfStatement`.
        expect(ifStmt.elseBranch, isA<IfStatement>());
        final elseIf = ifStmt.elseBranch! as IfStatement;
        expect(elseIf.condition, isA<IdentifierExpression>());
        expect(
          (elseIf.condition as IdentifierExpression).token.value,
          'b',
        );
        final elseIfBody = elseIf.body as OrderedStatements;
        expect((elseIfBody.statements[0] as TextOutputStatement).text, '2');

        expect(elseIf.elseBranch, isA<OrderedStatements>());
        final elseBody = elseIf.elseBranch! as OrderedStatements;
        expect((elseBody.statements[0] as TextOutputStatement).text, '3');
      });

      test('parses multiple else-if branches as nested chain', () {
        final parser = Parser(
          '{{ if a }}1{{ else if b }}2{{ else if c }}3{{ else }}4{{ /if }}',
        );
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        // First `else if` branch.
        expect(ifStmt.elseBranch, isA<IfStatement>());
        final elseIf1 = ifStmt.elseBranch! as IfStatement;
        expect(
          (elseIf1.condition as IdentifierExpression).token.value,
          'b',
        );
        final elseIf1Body = elseIf1.body as OrderedStatements;
        expect((elseIf1Body.statements[0] as TextOutputStatement).text, '2');

        // Second `else if` branch.
        expect(elseIf1.elseBranch, isA<IfStatement>());
        final elseIf2 = elseIf1.elseBranch! as IfStatement;
        expect(
          (elseIf2.condition as IdentifierExpression).token.value,
          'c',
        );
        final elseIf2Body = elseIf2.body as OrderedStatements;
        expect((elseIf2Body.statements[0] as TextOutputStatement).text, '3');

        // Final `else` branch.
        expect(elseIf2.elseBranch, isA<OrderedStatements>());
        final finalElse = elseIf2.elseBranch! as OrderedStatements;
        expect((finalElse.statements[0] as TextOutputStatement).text, '4');
      });

      test('parses nested if statements', () {
        final parser = Parser(
          '{{ if outer }}{{ if inner }}nested{{ /if }}{{ /if }}',
        );
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final outerIf = result as IfStatement;

        final outerBody = outerIf.body as OrderedStatements;
        expect(outerBody.statements.length, 1);
        expect(outerBody.statements[0], isA<IfStatement>());
        final innerIf = outerBody.statements[0] as IfStatement;

        final innerBody = innerIf.body as OrderedStatements;
        expect(innerBody.statements.length, 1);
        expect(
          (innerBody.statements[0] as TextOutputStatement).text,
          'nested',
        );
      });

      test('parses if with expression condition', () {
        final parser = Parser('{{ if user.isActive }}active{{ /if }}');
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        expect(ifStmt.condition, isA<PropertyAccessExpression>());
      });

      test('parses if with mixed body content', () {
        final parser = Parser(
          '{{ if show }}Hello {{ name }}!{{ /if }}',
        );
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        expect(ifStmt.body, isA<OrderedStatements>());
        final body = ifStmt.body as OrderedStatements;
        expect(body.statements.length, 3);
        expect(body.statements[0], isA<TextOutputStatement>());
        expect(body.statements[1], isA<ExpressionOutputStatement>());
        expect(body.statements[2], isA<TextOutputStatement>());
      });

      test('throws on missing /if end tag', () {
        final parser = Parser('{{ if show }}content');
        expect(parser.parse, throwsA(isA<ParseException>()));
      });

      test('parses if with boolean literal condition', () {
        final parser = Parser('{{ if true }}always{{ /if }}');
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        expect(ifStmt.condition, isA<LiteralExpression>());
        expect((ifStmt.condition as LiteralExpression).value, true);

        final body = ifStmt.body as OrderedStatements;
        expect(body.statements.length, 1);
        expect(
          (body.statements[0] as TextOutputStatement).text,
          'always',
        );
      });

      test('parses if with empty body', () {
        final parser = Parser('{{ if show }}{{ /if }}');
        final result = parser.parse();

        expect(result, isA<IfStatement>());
        final ifStmt = result as IfStatement;

        expect(ifStmt.body, isA<OrderedStatements>());
        expect((ifStmt.body as OrderedStatements).statements, isEmpty);
      });

      test('parses if surrounded by text', () {
        final parser = Parser('before{{ if show }}middle{{ /if }}after');
        final result = parser.parse();

        expect(result, isA<OrderedStatements>());
        final ordered = result as OrderedStatements;
        expect(ordered.statements.length, 3);
        expect(ordered.statements[0], isA<TextOutputStatement>());
        expect(ordered.statements[1], isA<IfStatement>());
        expect(ordered.statements[2], isA<TextOutputStatement>());
      });
    });

    group('Error handling', () {
      test('throws on unclosed tag', () {
        final parser = Parser('{{ name ');
        expect(parser.parse, throwsA(isA<ParseException>()));
      });

      test('throws on missing closing bracket', () {
        final parser = Parser('{{ array[0 }}');
        expect(parser.parse, throwsA(isA<ParseException>()));
      });

      test('throws on missing closing parenthesis', () {
        final parser = Parser('{{ func(arg }}');
        expect(parser.parse, throwsA(isA<ParseException>()));
      });

      test('throws on invalid token in expression', () {
        final parser = Parser('{{ , }}');
        expect(parser.parse, throwsA(isA<ParseException>()));
      });

      test('throws on missing property name after dot', () {
        final parser = Parser('{{ user. }}');
        expect(parser.parse, throwsA(isA<ParseException>()));
      });

      test('throws on empty index brackets', () {
        final parser = Parser('{{ array[] }}');
        expect(parser.parse, throwsA(isA<ParseException>()));
      });
    });

    group('Multiple statements', () {
      test('parses template with multiple expressions', () {
        final parser = Parser('''
        <h1>{{ title }}</h1>
        <p>{{ description }}</p>
        <span>Count: {{ items.length }}</span>
        ''');
        final result = parser.parse();

        expect(result, isA<OrderedStatements>());
        final ordered = result as OrderedStatements;

        final exprStatements = ordered.statements
            .whereType<ExpressionOutputStatement>()
            .toList();
        expect(exprStatements.length, 3);

        final first = exprStatements[0];
        expect(first.expression, isA<IdentifierExpression>());

        final third = exprStatements[2];
        expect(third.expression, isA<PropertyAccessExpression>());
      });

      test('parses alternating text and expressions', () {
        final parser = Parser('a{{ b }}c{{ d }}e');
        final result = parser.parse();

        expect(result, isA<OrderedStatements>());
        final ordered = result as OrderedStatements;
        expect(ordered.statements.length, 5);

        expect(ordered.statements[0], isA<TextOutputStatement>());
        expect(ordered.statements[1], isA<ExpressionOutputStatement>());
        expect(ordered.statements[2], isA<TextOutputStatement>());
        expect(ordered.statements[3], isA<ExpressionOutputStatement>());
        expect(ordered.statements[4], isA<TextOutputStatement>());
      });
    });
  });
}
