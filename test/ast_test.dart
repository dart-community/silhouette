import 'package:silhouette/silhouette.dart';
import 'package:silhouette/src/ast.dart';
import 'package:silhouette/src/token.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Statement classes', () {
    group('OrderedStatements', () {
      test('stores list of statements', () {
        const textStmt = TextOutputStatement('Hello');
        final exprStmt = ExpressionOutputStatement(
          IdentifierExpression(testToken(TokenType.identifier, 'name')),
        );
        final orderedStmts = OrderedStatements([textStmt, exprStmt]);

        expect(orderedStmts.statements.length, equals(2));
        expect(orderedStmts.statements[0], same(textStmt));
        expect(orderedStmts.statements[1], same(exprStmt));
      });

      test('can be empty', () {
        const orderedStmts = OrderedStatements([]);
        expect(orderedStmts.statements, isEmpty);
      });
    });

    group('TextOutputStatement', () {
      test('stores text content', () {
        const stmt = TextOutputStatement('Hello World');
        expect(stmt.text, equals('Hello World'));
      });

      test('can store empty text', () {
        const stmt = TextOutputStatement('');
        expect(stmt.text, isEmpty);
      });
    });

    group('ExpressionOutputStatement', () {
      test('stores expression', () {
        final expr = IdentifierExpression(
          testToken(TokenType.identifier, 'name'),
        );
        final stmt = ExpressionOutputStatement(expr);
        expect(stmt.expression, same(expr));
      });
    });

    group('IfStatement', () {
      test('stores condition and body', () {
        final condition = IdentifierExpression(
          testToken(TokenType.identifier, 'show'),
        );
        const body = TextOutputStatement('Hello');
        final stmt = IfStatement(condition: condition, body: body);

        expect(stmt.condition, same(condition));
        expect(stmt.body, same(body));
        expect(stmt.elseBranch, isNull);
      });

      test('stores else branch as a plain statement', () {
        final condition = IdentifierExpression(
          testToken(TokenType.identifier, 'a'),
        );
        const body = TextOutputStatement('yes');
        const elseBranch = TextOutputStatement('no');

        final stmt = IfStatement(
          condition: condition,
          body: body,
          elseBranch: elseBranch,
        );

        expect(stmt.elseBranch, same(elseBranch));
      });

      test('stores else-if as a nested IfStatement', () {
        final innerCondition = IdentifierExpression(
          testToken(TokenType.identifier, 'b'),
        );
        const innerBody = TextOutputStatement('2');
        const elseBody = TextOutputStatement('3');
        final innerIf = IfStatement(
          condition: innerCondition,
          body: innerBody,
          elseBranch: elseBody,
        );

        final outerCondition = IdentifierExpression(
          testToken(TokenType.identifier, 'a'),
        );
        const outerBody = TextOutputStatement('1');
        final outerIf = IfStatement(
          condition: outerCondition,
          body: outerBody,
          elseBranch: innerIf,
        );

        expect(outerIf.elseBranch, isA<IfStatement>());
        final nested = outerIf.elseBranch! as IfStatement;
        expect(nested.condition, same(innerCondition));
        expect(nested.body, same(innerBody));
        expect(nested.elseBranch, same(elseBody));
      });
    });

    group('ForStatement', () {
      test('stores variable, iterable, and body', () {
        final variable = testToken(TokenType.identifier, 'item');
        final iterable = IdentifierExpression(
          testToken(TokenType.identifier, 'items'),
        );
        const body = TextOutputStatement('Hello');
        final stmt = ForStatement(
          variable: variable,
          iterable: iterable,
          body: body,
        );

        expect(stmt.variable, same(variable));
        expect(stmt.iterable, same(iterable));
        expect(stmt.body, same(body));
      });
    });
  });

  group('Expression classes', () {
    group('IdentifierExpression', () {
      test('stores token', () {
        final token = testToken(TokenType.identifier, 'variableName');
        final expr = IdentifierExpression(token);

        expect(expr.token, same(token));
      });
    });

    group('LiteralExpression', () {
      test('stores token and value', () {
        final token = testToken(TokenType.stringLiteral, '"hello"');
        final expr = LiteralExpression(token, value: 'hello');

        expect(expr.token, same(token));
        expect(expr.value, equals('hello'));
      });

      test('can have null value', () {
        final token = testToken(TokenType.nullKeyword, 'null');
        final expr = LiteralExpression(token, value: null);

        expect(expr.token, same(token));
        expect(expr.value, isNull);
      });
    });

    group('PropertyAccessExpression', () {
      test('stores object, dot token, and identifier', () {
        final objectExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'user'),
        );
        final dotToken = testToken(TokenType.dot, '.');
        final identifierToken = testToken(TokenType.identifier, 'name');

        final expr = PropertyAccessExpression(
          objectExpr,
          dotToken,
          identifierToken,
        );

        expect(expr.object, same(objectExpr));
        expect(expr.dotToken, same(dotToken));
        expect(expr.identifier, same(identifierToken));
      });
    });

    group('IndexAccessExpression', () {
      test('stores object, brackets, and index expression', () {
        final objectExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'array'),
        );
        final leftBracketToken = testToken(TokenType.openSquareBracket, '[');
        final indexExpr = LiteralExpression(
          testToken(TokenType.numberLiteral, '0'),
          value: 0,
        );
        final rightBracketToken = testToken(TokenType.closeSquareBracket, ']');

        final expr = IndexAccessExpression(
          objectExpr,
          leftBracketToken,
          indexExpr,
          rightBracketToken,
        );

        expect(expr.object, same(objectExpr));
        expect(expr.leftBracketToken, same(leftBracketToken));
        expect(expr.index, same(indexExpr));
        expect(expr.rightBracketToken, same(rightBracketToken));
      });
    });

    group('CallExpression', () {
      test('stores callee, parentheses, and arguments', () {
        final calleeExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'func'),
        );
        final leftParenToken = testToken(TokenType.openParenthesis, '(');
        final positionalArg = LiteralExpression(
          testToken(TokenType.stringLiteral, '"test"'),
          value: 'test',
        );
        final namedArgValue = LiteralExpression(
          testToken(TokenType.numberLiteral, '42'),
          value: 42,
        );
        final rightParenToken = testToken(TokenType.closeParenthesis, ')');

        final expr = CallExpression(
          calleeExpr,
          leftParenToken,
          [positionalArg],
          {SilhouetteIdentifier('key'): namedArgValue},
          rightParenToken,
        );

        expect(expr.callee, same(calleeExpr));
        expect(expr.leftParenToken, same(leftParenToken));
        expect(expr.positionalArguments.length, equals(1));
        expect(expr.positionalArguments[0], same(positionalArg));
        expect(expr.namedArguments.length, equals(1));
        expect(
          expr.namedArguments[SilhouetteIdentifier('key')],
          same(namedArgValue),
        );
        expect(expr.rightParenToken, same(rightParenToken));
      });

      test('can have no arguments', () {
        final calleeExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'func'),
        );
        final expr = CallExpression(
          calleeExpr,
          testToken(TokenType.openParenthesis, '('),
          const [],
          const {},
          testToken(TokenType.closeParenthesis, ')'),
        );

        expect(expr.positionalArguments, isEmpty);
        expect(expr.namedArguments, isEmpty);
      });
    });
  });
}
