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
    final evaluator = _TemplateEvaluator([
      _ObjectScope(_globalContext),
      if (context != null) _ObjectScope(context),
    ]);
    await evaluator._executeStatement(statement);
    return evaluator._output.toString();
  }
}

/// A frame in the renderer's identifier lookup chain.
///
/// Implementations return `null` for unbound identifiers.
abstract interface class _Scope {
  /// The value bound to [name], if this scope contains one.
  SilhouetteValue? lookup(SilhouetteIdentifier name);
}

/// A scope frame backed by a [SilhouetteObject].
final class _ObjectScope implements _Scope {
  /// Creates a scope frame for [object].
  _ObjectScope(this.object);

  /// The object that supplies bindings for this scope.
  final SilhouetteObject object;

  /// Returns the value assigned to [name] in [object], if present.
  @override
  SilhouetteValue? lookup(SilhouetteIdentifier name) => object.value[name];
}

/// A scope frame for a single reusable loop variable binding.
///
/// The renderer mutates [value] for each loop iteration while keeping this
/// frame on the scope chain for the duration of the loop.
final class _LoopScope implements _Scope {
  /// Creates a scope frame that binds [name].
  _LoopScope(this.name);

  /// The identifier this scope binds.
  final SilhouetteIdentifier name;

  /// The value currently bound to [name].
  late SilhouetteValue value;

  /// Returns the current [value] when [candidate] matches [name].
  @override
  SilhouetteValue? lookup(SilhouetteIdentifier candidate) =>
      candidate == name ? value : null;
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
  final List<_Scope> _scopes;

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

    final loopScope = _LoopScope(variableName);
    _scopes.add(loopScope);
    try {
      for (final element in iterableValue.values) {
        loopScope.value = element;
        await _executeStatement(stmt.body);
      }
    } finally {
      _scopes.removeLast();
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
      if (scope.lookup(key) case final value?) {
        return value;
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
