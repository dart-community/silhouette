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
    final evaluator = _TemplateEvaluator(
      _ScopeChain([
        _ObjectScope(_globalContext),
        if (context != null) _ObjectScope(context),
      ]),
    );
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

/// The renderer's identifier lookup chain.
///
/// Scopes are searched from innermost to outermost,
/// so inner scopes such as loop variables shadow
/// the render context and global variables.
extension type _ScopeChain(List<_Scope> _scopes) {
  /// Adds [scope] as the new innermost scope.
  void push(_Scope scope) => _scopes.add(scope);

  /// Removes the innermost scope.
  void pop() => _scopes.removeLast();

  /// The value bound to [name] in the innermost scope that binds it, if any.
  SilhouetteValue? lookup(SilhouetteIdentifier name) {
    for (var i = _scopes.length - 1; i >= 0; i -= 1) {
      if (_scopes[i].lookup(name) case final value?) {
        return value;
      }
    }
    return null;
  }
}

/// Internal evaluator that walks the AST with exhaustive `switch` dispatch.
///
/// Handles the actual evaluation of a single parent statement or expression.
final class _TemplateEvaluator {
  /// The scope chain for variable resolution.
  final _ScopeChain _scopes;

  /// Buffer for collecting template output during evaluation.
  final StringBuffer _output = StringBuffer();

  /// Creates an evaluator with the given scope chain.
  _TemplateEvaluator(this._scopes);

  /// Executes [stmt], writing any output it produces to [_output].
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

  /// Executes the body of [stmt] once for each element of its iterable.
  ///
  /// The loop variable is bound in a new innermost scope,
  /// which is removed when the loop completes, even if the body throws.
  ///
  /// Throws a [SilhouetteException] if the iterable expression
  /// doesn't evaluate to a [SilhouetteIterable].
  Future<void> _executeForStatement(ForStatement stmt) async {
    final iterableValue = await _evaluateExpression(stmt.iterable);
    if (iterableValue is! SilhouetteIterable<SilhouetteValue>) {
      throw SilhouetteException(
        'For loop requires an iterable, got ${iterableValue.runtimeType}',
      );
    }

    final loopScope = _LoopScope(stmt.variableName);
    _scopes.push(loopScope);
    try {
      for (final element in iterableValue.values) {
        loopScope.value = element;
        await _executeStatement(stmt.body);
      }
    } finally {
      _scopes.pop();
    }
  }

  /// Executes the body of [stmt] if its condition is `true`,
  /// otherwise executes its else branch, if it has one.
  ///
  /// Throws a [SilhouetteException] if the condition
  /// doesn't evaluate to a [SilhouetteBool].
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

  /// Evaluates [expr] and returns the resulting value.
  Future<SilhouetteValue> _evaluateExpression(Expression expr) async {
    return switch (expr) {
      IdentifierExpression() => _evaluateIdentifier(expr),
      LiteralExpression() => _evaluateLiteral(expr),
      PropertyAccessExpression() => await _evaluatePropertyAccess(expr),
      IndexAccessExpression() => await _evaluateIndexAccess(expr),
      CallExpression() => await _evaluateCall(expr),
    };
  }

  /// Returns the value bound to the name of [identifier]
  /// in the innermost scope that binds it.
  ///
  /// Throws a [SilhouetteException] if no scope binds the name.
  SilhouetteValue _evaluateIdentifier(IdentifierExpression identifier) {
    final name = identifier.name;

    if (_scopes.lookup(name) case final value?) {
      return value;
    }

    throw SilhouetteException('Undefined variable: $name');
  }

  /// Converts the parsed Dart value of [literal]
  /// to its corresponding [SilhouetteValue].
  SilhouetteValue _evaluateLiteral(LiteralExpression literal) {
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

  /// Evaluates the object of [access],
  /// then retrieves the accessed property from it.
  Future<SilhouetteValue> _evaluatePropertyAccess(
    PropertyAccessExpression access,
  ) async {
    final object = await _evaluateExpression(access.object);
    return await object.retrieve(access.name);
  }

  /// Evaluates the object and then the index of [access],
  /// and looks up the index in the object.
  ///
  /// Throws a [SilhouetteException] if the object isn't [SilhouetteIndexable].
  Future<SilhouetteValue> _evaluateIndexAccess(
    IndexAccessExpression access,
  ) async {
    final object = await _evaluateExpression(access.object);
    final indexValue = await _evaluateExpression(access.index);

    if (object is! SilhouetteIndexable) {
      throw SilhouetteException(
        'Cannot index ${object.runtimeType} - not indexable',
      );
    }

    return object.forKey(indexValue);
  }

  /// Evaluates the callee of [call] and, if it's a [SilhouetteFunction],
  /// evaluates the arguments and calls the function with them.
  ///
  /// Throws a [SilhouetteException] if the callee isn't a [SilhouetteFunction].
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

  /// Evaluates the arguments of [call],
  /// positional arguments first, then named arguments,
  /// each in the order they appear in the source.
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
