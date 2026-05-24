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

      test('matches IfStatement in a sealed switch', () {
        final condition = IdentifierExpression(
          testToken(TokenType.identifier, 'show'),
        );
        const body = TextOutputStatement('Hello');
        final Statement stmt = IfStatement(condition: condition, body: body);

        expect(_statementKind(stmt), equals('ifStatement'));
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

      test('matches ForStatement in a sealed switch', () {
        final variable = testToken(TokenType.identifier, 'item');
        final iterable = IdentifierExpression(
          testToken(TokenType.identifier, 'items'),
        );
        const body = TextOutputStatement('Hello');
        final Statement stmt = ForStatement(
          variable: variable,
          iterable: iterable,
          body: body,
        );

        expect(_statementKind(stmt), equals('forStatement'));
      });
    });
  });

  group('Expression classes', () {
    group('IdentifierExpression', () {
      test('stores token and matches in a sealed switch', () {
        final token = testToken(TokenType.identifier, 'variableName');
        final Expression expr = IdentifierExpression(token);

        expect((expr as IdentifierExpression).token, same(token));
        expect(_expressionKind(expr), equals('identifier'));
      });
    });

    group('LiteralExpression', () {
      test('stores token and value', () {
        final token = testToken(TokenType.stringLiteral, '"hello"');
        final expr = LiteralExpression(token, value: 'hello');

        expect(expr.token, same(token));
        expect(expr.value, equals('hello'));
      });

      test('matches LiteralExpression in a sealed switch', () {
        final token = testToken(TokenType.numberLiteral, '42');
        final Expression expr = LiteralExpression(token, value: 42);

        expect(_expressionKind(expr), equals('literal'));
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

      test('matches PropertyAccessExpression in a sealed switch', () {
        final objectExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'obj'),
        );
        final Expression expr = PropertyAccessExpression(
          objectExpr,
          testToken(TokenType.dot, '.'),
          testToken(TokenType.identifier, 'prop'),
        );

        expect(_expressionKind(expr), equals('propertyAccess'));
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

      test('matches IndexAccessExpression in a sealed switch', () {
        final objectExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'arr'),
        );
        final indexExpr = LiteralExpression(
          testToken(TokenType.numberLiteral, '1'),
          value: 1,
        );
        final Expression expr = IndexAccessExpression(
          objectExpr,
          testToken(TokenType.openSquareBracket, '['),
          indexExpr,
          testToken(TokenType.closeSquareBracket, ']'),
        );

        expect(_expressionKind(expr), equals('indexAccess'));
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

      test('matches CallExpression in a sealed switch', () {
        final calleeExpr = IdentifierExpression(
          testToken(TokenType.identifier, 'fn'),
        );
        final Expression expr = CallExpression(
          calleeExpr,
          testToken(TokenType.openParenthesis, '('),
          const [],
          const {},
          testToken(TokenType.closeParenthesis, ')'),
        );

        expect(_expressionKind(expr), equals('call'));
      });
    });
  });

  group('Sealed dispatch integration', () {
    test('complex expression tree dispatches via switch', () {
      // Create expression: user.getName(true, format: "short")
      final userExpr = IdentifierExpression(
        testToken(TokenType.identifier, 'user'),
      );
      final propertyExpr = PropertyAccessExpression(
        userExpr,
        testToken(TokenType.dot, '.'),
        testToken(TokenType.identifier, 'getName'),
      );
      final Expression callExpr = CallExpression(
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

      expect(_expressionKind(callExpr), equals('call'));
    });

    test('nested property access dispatches via switch', () {
      // Create expression: user.profile.name
      final userExpr = IdentifierExpression(
        testToken(TokenType.identifier, 'user'),
      );
      final profileExpr = PropertyAccessExpression(
        userExpr,
        testToken(TokenType.dot, '.'),
        testToken(TokenType.identifier, 'profile'),
      );
      final Expression nameExpr = PropertyAccessExpression(
        profileExpr,
        testToken(TokenType.dot, '.'),
        testToken(TokenType.identifier, 'name'),
      );

      expect(_expressionKind(nameExpr), equals('propertyAccess'));
    });

    test('array access with expression index dispatches via switch', () {
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
      final Expression expr = IndexAccessExpression(
        itemsExpr,
        testToken(TokenType.openSquareBracket, '['),
        propertyExpr,
        testToken(TokenType.closeSquareBracket, ']'),
      );

      expect(_expressionKind(expr), equals('indexAccess'));
    });
  });
}

/// Returns a label for the concrete subtype of [stmt] using exhaustive
/// switch dispatch over the sealed [Statement] hierarchy.
String _statementKind(Statement stmt) => switch (stmt) {
  OrderedStatements() => 'orderedStatements',
  TextOutputStatement() => 'textOutput',
  ExpressionOutputStatement() => 'expressionOutput',
  IfStatement() => 'ifStatement',
  ForStatement() => 'forStatement',
};

/// Returns a label for the concrete subtype of [expr] using exhaustive
/// switch dispatch over the sealed [Expression] hierarchy.
String _expressionKind(Expression expr) => switch (expr) {
  IdentifierExpression() => 'identifier',
  LiteralExpression() => 'literal',
  PropertyAccessExpression() => 'propertyAccess',
  IndexAccessExpression() => 'indexAccess',
  CallExpression() => 'call',
};
