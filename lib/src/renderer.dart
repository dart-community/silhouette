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
    await statement.accept(evaluator);
    return evaluator._output.toString();
  }
}

/// Internal evaluator that implements the visitor pattern for AST traversal.
///
/// Handles the actual evaluation of a single parent statement or expression.
final class _TemplateEvaluator
    implements
        ExpressionVisitor<Future<SilhouetteValue>>,
        StatementVisitor<Future<void>> {
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

  @override
  Future<void> visitOrderedStatements(OrderedStatements stmt) async {
    for (final childStmt in stmt.statements) {
      await childStmt.accept(this);
    }
  }

  @override
  Future<void> visitTextOutput(TextOutputStatement stmt) async {
    _output.write(stmt.text);
  }

  @override
  Future<void> visitExpressionOutput(ExpressionOutputStatement stmt) async {
    final value = await stmt.expression.accept(this);
    _output.write(value.toString());
  }

  @override
  Future<SilhouetteValue> visitIdentifier(
    IdentifierExpression identifier,
  ) async {
    final key = SilhouetteIdentifier(identifier.token.value);

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

  @override
  Future<SilhouetteValue> visitLiteral(LiteralExpression literal) async {
    final value = literal.value;
    return switch (value) {
      null => SilhouetteNull(),
      String() => SilhouetteString(value),
      int() => SilhouetteInt(value),
      double() => SilhouetteDouble(value),
      bool() => SilhouetteBool(value),
      _ => throw SilhouetteException(
        'Unsupported literal type: ${value.runtimeType}',
      ),
    };
  }

  @override
  Future<SilhouetteValue> visitPropertyAccess(
    PropertyAccessExpression access,
  ) async {
    final object = await access.object.accept(this);
    return await object.retrieve(SilhouetteIdentifier(access.identifier.value));
  }

  @override
  Future<SilhouetteValue> visitIndexAccess(
    IndexAccessExpression access,
  ) async {
    final object = await access.object.accept(this);
    final indexValue = await access.index.accept(this);

    if (object is! SilhouetteIndexable) {
      throw SilhouetteException(
        'Cannot index ${object.runtimeType} - not indexable',
      );
    }

    return object.forKey(indexValue);
  }

  @override
  Future<SilhouetteValue> visitCall(CallExpression call) async {
    final target = await call.callee.accept(this);

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
          for (final arg in call.positionalArguments) await arg.accept(this),
        ],
        named: {
          for (final MapEntry(:key, :value) in call.namedArguments.entries)
            SilhouetteIdentifier(key): await value.accept(this),
        },
      );
}
