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
  });

  group('Expression classes', () {
    group('IdentifierExpression', () {
      test('stores token and implements visitor pattern', () {
        final token = testToken(TokenType.identifier, 'variableName');
        final expr = IdentifierExpression(token);

        expect(expr.token, same(token));

        // Test visitor pattern.
        final visitor = _TestVisitor();
        final result = expr.accept(visitor);
        expect(result, equals('identifier'));
        expect(visitor.lastIdentifierExpr, same(expr));
      });
    });

    group('LiteralExpression', () {
      test('stores token and value', () {
        final token = testToken(TokenType.stringLiteral, '"hello"');
        final expr = LiteralExpression(token, value: 'hello');

        expect(expr.token, same(token));
        expect(expr.value, equals('hello'));
      });

      test('implements visitor pattern', () {
        final token = testToken(TokenType.numberLiteral, '42');
        final expr = LiteralExpression(token, value: 42);

        final visitor = _TestVisitor();
        final result = expr.accept(visitor);
        expect(result, equals('literal'));
        expect(visitor.lastLiteralExpr, same(expr));
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

      test('implements visitor pattern', () {
        final objectExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'obj'),
        );
        final expr = PropertyAccessExpression(
          objectExpr,
          testToken(TokenType.dot, '.'),
          testToken(TokenType.identifier, 'prop'),
        );

        final visitor = _TestVisitor();
        final result = expr.accept(visitor);
        expect(result, equals('propertyAccess'));
        expect(visitor.lastPropertyAccessExpr, same(expr));
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

      test('implements visitor pattern', () {
        final objectExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'arr'),
        );
        final indexExpr = LiteralExpression(
          testToken(TokenType.numberLiteral, '1'),
          value: 1,
        );
        final expr = IndexAccessExpression(
          objectExpr,
          testToken(TokenType.openSquareBracket, '['),
          indexExpr,
          testToken(TokenType.closeSquareBracket, ']'),
        );

        final visitor = _TestVisitor();
        final result = expr.accept(visitor);
        expect(result, equals('indexAccess'));
        expect(visitor.lastIndexAccessExpr, same(expr));
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
          {'key': namedArgValue},
          rightParenToken,
        );

        expect(expr.callee, same(calleeExpr));
        expect(expr.leftParenToken, same(leftParenToken));
        expect(expr.positionalArguments.length, equals(1));
        expect(expr.positionalArguments[0], same(positionalArg));
        expect(expr.namedArguments.length, equals(1));
        expect(expr.namedArguments['key'], same(namedArgValue));
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

      test('implements visitor pattern', () {
        final calleeExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'fn'),
        );
        final expr = CallExpression(
          calleeExpr,
          testToken(TokenType.openParenthesis, '('),
          const [],
          const {},
          testToken(TokenType.closeParenthesis, ')'),
        );

        final visitor = _TestVisitor();
        final result = expr.accept(visitor);
        expect(result, equals('call'));
        expect(visitor.lastCallExpr, same(expr));
      });
    });
  });

  group('Visitor pattern integration', () {
    test('complex expression tree works with visitor', () {
      // Create expression: user.getName(true, format: "short")
      final userExpr = IdentifierExpression(
        testToken(TokenType.identifier, 'user'),
      );
      final propertyExpr = PropertyAccessExpression(
        userExpr,
        testToken(TokenType.dot, '.'),
        testToken(TokenType.identifier, 'getName'),
      );
      final callExpr = CallExpression(
        propertyExpr,
        testToken(TokenType.openParenthesis, '('),
        [
          LiteralExpression(
            testToken(TokenType.trueKeyword, 'true'),
            value: true,
          ),
        ],
        {
          'format': LiteralExpression(
            testToken(TokenType.stringLiteral, '"short"'),
            value: 'short',
          ),
        },
        testToken(TokenType.closeParenthesis, ')'),
      );

      final visitor = _TestVisitor();
      final result = callExpr.accept(visitor);
      expect(result, equals('call'));
      expect(visitor.lastCallExpr, same(callExpr));
    });

    test('nested property access works with visitor', () {
      // Create expression: user.profile.name
      final userExpr = IdentifierExpression(
        testToken(TokenType.identifier, 'user'),
      );
      final profileExpr = PropertyAccessExpression(
        userExpr,
        testToken(TokenType.dot, '.'),
        testToken(TokenType.identifier, 'profile'),
      );
      final nameExpr = PropertyAccessExpression(
        profileExpr,
        testToken(TokenType.dot, '.'),
        testToken(TokenType.identifier, 'name'),
      );

      final visitor = _TestVisitor();
      final result = nameExpr.accept(visitor);
      expect(result, equals('propertyAccess'));
      expect(visitor.lastPropertyAccessExpr, same(nameExpr));
    });

    test('array access with expression index works', () {
      // Create expression: items[key.index]
      final itemsExpr = IdentifierExpression(
        testToken(TokenType.identifier, 'items'),
      );
      final keyExpr = IdentifierExpression(
        testToken(TokenType.identifier, 'key'),
      );
      final propertyExpr = PropertyAccessExpression(
        keyExpr,
        testToken(TokenType.dot, '.'),
        testToken(TokenType.identifier, 'index'),
      );
      final expr = IndexAccessExpression(
        itemsExpr,
        testToken(TokenType.openSquareBracket, '['),
        propertyExpr,
        testToken(TokenType.closeSquareBracket, ']'),
      );

      final visitor = _TestVisitor();
      final result = expr.accept(visitor);
      expect(result, equals('indexAccess'));
      expect(visitor.lastIndexAccessExpr, same(expr));
    });
  });
}

/// Test implementation of ExpressionVisitor for testing the visitor pattern.
class _TestVisitor implements ExpressionVisitor<String> {
  IdentifierExpression? lastIdentifierExpr;
  LiteralExpression? lastLiteralExpr;
  PropertyAccessExpression? lastPropertyAccessExpr;
  IndexAccessExpression? lastIndexAccessExpr;
  CallExpression? lastCallExpr;

  @override
  String visitIdentifier(IdentifierExpression expr) {
    lastIdentifierExpr = expr;
    return 'identifier';
  }

  @override
  String visitLiteral(LiteralExpression expr) {
    lastLiteralExpr = expr;
    return 'literal';
  }

  @override
  String visitPropertyAccess(PropertyAccessExpression expr) {
    lastPropertyAccessExpr = expr;
    return 'propertyAccess';
  }

  @override
  String visitIndexAccess(IndexAccessExpression expr) {
    lastIndexAccessExpr = expr;
    return 'indexAccess';
  }

  @override
  String visitCall(CallExpression expr) {
    lastCallExpr = expr;
    return 'call';
  }
}
