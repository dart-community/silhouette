import 'package:meta/meta.dart';

import 'ast.dart';
import 'exceptions.dart';
import 'value.dart';

/// Renderer for executing template statements and expressions.
///
/// Handles the runtime evaluation of the parsed Silhouette AST, including:
///
/// - Statement execution (text output, expression evaluation)
/// - Expression evaluation (variables, properties, calls)
/// - Method dispatch for built-in operations
/// - Error handling and reporting
@internal
final class TemplateRenderer {
  /// The global context containing built-in top-level values.
  final SilhouetteObject _globalContext;

  /// Creates a template renderer with the given [_globalContext].
  const TemplateRenderer(this._globalContext);

  /// Evaluates a statement and returns the complete output.
  ///
  /// This is the main entry point for template evaluation.
  /// It executes the given [statement] and
  /// returns the rendered output as a string.
  @useResult
  Future<String> evaluate(
    Statement statement, [
    SilhouetteObject? context,
  ]) async {
    final evaluator = _TemplateEvaluator([_globalContext, ?context]);
    await evaluator._executeStatement(statement);
    return evaluator._output.toString();
  }
}

/// Internal evaluator that walks the AST with exhaustive `switch` dispatch.
///
/// Handles the actual evaluation of a single parent statement or expression.
final class _TemplateEvaluator {
  /// The scope chain for variable resolution.
  ///
  /// Scopes are searched from innermost (end of list) to outermost (beginning)
  /// for variable resolution. This supports nested scopes for future features
  /// like conditionals and loops.
  final List<SilhouetteObject> _scopes;

  /// Buffer for collecting template output during evaluation.
  final StringBuffer _output = StringBuffer();

  /// Creates an evaluator with the given scope chain.
  ///
  /// The [_scopes] list should be ordered from outermost to innermost scope.
  _TemplateEvaluator(this._scopes);

  Future<void> _executeStatement(Statement stmt) async {
    switch (stmt) {
      case OrderedStatements(:final statements):
        for (final childStmt in statements) {
          await _executeStatement(childStmt);
        }
      case TextOutputStatement(:final text):
        _output.write(text);
      case ExpressionOutputStatement(:final expression):
        final value = await _evaluateExpression(expression);
        _output.write(value.toString());
      case ForStatement():
        await _executeForStatement(stmt);
      case IfStatement():
        await _executeIfStatement(stmt);
    }
  }

  Future<void> _executeForStatement(ForStatement stmt) async {
    final iterableValue = await _evaluateExpression(stmt.iterable);
    if (iterableValue is! SilhouetteIterable<SilhouetteValue>) {
      throw SilhouetteException(
        'For loop requires an iterable, got ${iterableValue.runtimeType}',
      );
    }

    final variableName = SilhouetteIdentifier.trusted(stmt.variable.value);

    for (final element in iterableValue.values) {
      // Create a scope with the loop variable for each iteration.
      final loopScope = SilhouetteObject({variableName: element});
      _scopes.add(loopScope);
      try {
        await _executeStatement(stmt.body);
      } finally {
        _scopes.removeLast();
      }
    }
  }

  Future<void> _executeIfStatement(IfStatement stmt) async {
    final conditionValue = await _evaluateExpression(stmt.condition);
    if (conditionValue is! SilhouetteBool) {
      throw SilhouetteException(
        'If condition must be a boolean, got ${conditionValue.runtimeType}',
      );
    }

    if (conditionValue.value) {
      await _executeStatement(stmt.body);
    } else if (stmt.elseBranch case final elseBranch?) {
      await _executeStatement(elseBranch);
    }
  }

  Future<SilhouetteValue> _evaluateExpression(Expression expr) async {
    return switch (expr) {
      IdentifierExpression() => _evaluateIdentifier(expr),
      LiteralExpression(:final value) => switch (value) {
        null => SilhouetteNull(),
        String() => SilhouetteString(value),
        int() => SilhouetteInt(value),
        double() => SilhouetteDouble(value),
        bool() => SilhouetteBool(value),
        _ => throw SilhouetteException(
          'Unsupported literal type: ${value.runtimeType}',
        ),
      },
      PropertyAccessExpression(:final object, :final identifier) =>
        await (await _evaluateExpression(
          object,
        )).retrieve(SilhouetteIdentifier.trusted(identifier.value)),
      IndexAccessExpression(:final object, :final index) =>
        await _evaluateIndexAccess(object, index),
      CallExpression() => await _evaluateCall(expr),
    };
  }

  Future<SilhouetteValue> _evaluateIdentifier(
    IdentifierExpression identifier,
  ) async {
    final key = SilhouetteIdentifier.trusted(identifier.token.value);

    // Try each scope from innermost to outermost.
    for (final scope in _scopes.reversed) {
      try {
        return await scope.retrieve(key);
      } on UnknownPropertyException {
        // Continue to next scope if variable not found in current scope.
        continue;
      }
    }

    // If not found in any scope, throw exception.
    throw SilhouetteException(
      'Undefined variable: ${identifier.token.value}',
    );
  }

  Future<SilhouetteValue> _evaluateIndexAccess(
    Expression objectExpr,
    Expression indexExpr,
  ) async {
    final object = await _evaluateExpression(objectExpr);
    final indexValue = await _evaluateExpression(indexExpr);

    if (object is! SilhouetteIndexable) {
      throw SilhouetteException(
        'Cannot index ${object.runtimeType} - not indexable',
      );
    }

    return object.forKey(indexValue);
  }

  Future<SilhouetteValue> _evaluateCall(CallExpression call) async {
    final target = await _evaluateExpression(call.callee);

    if (target is SilhouetteFunction) {
      final evaluatedArguments = await _evaluateArguments(call);
      return await target.call(evaluatedArguments);
    }

    throw SilhouetteException(
      'Can\'t call ${target.runtimeType} as a function',
    );
  }

  Future<SilhouetteArguments> _evaluateArguments(CallExpression call) async =>
      SilhouetteArguments(
        positional: [
          for (final arg in call.positionalArguments)
            await _evaluateExpression(arg),
        ],
        named: {
          for (final MapEntry(:key, :value) in call.namedArguments.entries)
            key: await _evaluateExpression(value),
        },
      );
}
