import 'package:meta/meta.dart';

import 'token.dart';

/// Abstract base class for each AST statement node in Silhouette.
///
/// Statements represent the structural components of a template, including
/// text content, expression outputs, and ordered sequences of statements.
///
/// This class uses the visitor pattern for traversal and evaluation.
/// Implementations must provide an [accept] method that
/// delegates to the appropriate visitor method.
@immutable
abstract base class Statement {
  /// Creates a new statement.
  const Statement();

  /// Accepts a [visitor] and delegates to the appropriate visit method.
  R accept<R>(StatementVisitor<R> visitor);
}

/// A statement that contains an ordered sequence of child statements.
///
/// Used to represent templates that contain multiple components,
/// such as text mixed with expressions.
/// The statements are executed in the order they appear in the list.
///
/// For example, `Hello {{ name }}!` would produce an [OrderedStatements]
/// containing a [TextOutputStatement] for "Hello ", an
/// [ExpressionOutputStatement] for the name variable, and another
/// [TextOutputStatement] for "!".
@immutable
final class OrderedStatements extends Statement {
  /// The list of statements to execute in order.
  final List<Statement> statements;

  /// Creates an ordered statements container with the given [statements].
  const OrderedStatements(this.statements);

  @override
  R accept<R>(StatementVisitor<R> visitor) =>
      visitor.visitOrderedStatements(this);
}

/// A statement that outputs static text content.
///
/// Represents literal text in a template that should be output as-is
/// without any processing or evaluation.
final class TextOutputStatement extends Statement {
  /// The text content to output.
  final String text;

  /// Creates a text output statement with the given [text].
  const TextOutputStatement(this.text);

  @override
  R accept<R>(StatementVisitor<R> visitor) => visitor.visitTextOutput(this);
}

/// A statement that evaluates and outputs an expression.
///
/// Represents template expressions wrapped in `{{ }}` delimiters that
/// need to be evaluated and their result converted to text for output.
@immutable
final class ExpressionOutputStatement extends Statement {
  /// The expression to evaluate and output.
  final Expression expression;

  /// Creates an expression output statement with the given [expression].
  const ExpressionOutputStatement(this.expression);

  @override
  R accept<R>(StatementVisitor<R> visitor) =>
      visitor.visitExpressionOutput(this);
}

/// Visitor interface for traversing and operating on statement nodes.
///
/// This interface defines methods for
/// visiting each type of statement in the AST.
/// Implementations can perform various operations such as
/// rendering, code generation, or static analysis.
abstract interface class StatementVisitor<R> {
  /// Visits an ordered statements container.
  R visitOrderedStatements(OrderedStatements stmt);

  /// Visits a text output statement.
  R visitTextOutput(TextOutputStatement stmt);

  /// Visits an expression output statement.
  R visitExpressionOutput(ExpressionOutputStatement stmt);
}

/// Abstract base class for all expression nodes in the AST.
///
/// Expressions represent computations that can be evaluated to produce values,
/// such as variable references, literals, property accesses,
/// method calls, and indexing operations.
///
/// Uses the visitor pattern for traversal and evaluation.
/// Implementations must provide an [accept] method that
/// delegates to the appropriate visitor method.
@immutable
abstract base class Expression {
  /// Creates a new expression.
  const Expression();

  /// Accepts a [visitor] and delegates to the appropriate visit method.
  R accept<R>(ExpressionVisitor<R> visitor);
}

/// Visitor interface for traversing and operating on expression nodes.
///
/// This interface defines methods for visiting each type of expression
/// in the AST. Implementations can perform various operations such as
/// evaluation, code generation, or static analysis.
abstract interface class ExpressionVisitor<R> {
  /// Visits an identifier expression.
  R visitIdentifier(IdentifierExpression expr);

  /// Visits a literal expression.
  R visitLiteral(LiteralExpression expr);

  /// Visits a property access expression.
  R visitPropertyAccess(PropertyAccessExpression expr);

  /// Visits an index access expression.
  R visitIndexAccess(IndexAccessExpression expr);

  /// Visits a function call expression.
  R visitCall(CallExpression expr);
}

/// An expression representing a variable or identifier reference.
///
/// Used for simple variable lookups in templates,
/// such as `{{ name }}` or `{{ user }}`.
/// The identifier's name is stored in the associated token.
@immutable
final class IdentifierExpression extends Expression {
  /// The token containing the identifier name and source location.
  final Token token;

  /// Creates an identifier expression from the given [token].
  const IdentifierExpression(this.token);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitIdentifier(this);
}

/// An expression representing a literal value.
///
/// This includes string literals, number literals, boolean literals,
/// and null literals. The actual parsed value is stored alongside the
/// original token for source location tracking.
@immutable
final class LiteralExpression extends Expression {
  /// The token containing the original literal text and source location.
  final Token token;

  /// The parsed literal value.
  ///
  /// This can be:
  /// - `String` for string literals
  /// - `int` or `double` for number literals
  /// - `bool` for boolean literals
  /// - `null` for null literals
  final Object? value;

  /// Creates a literal expression with the given [token] and parsed [value].
  const LiteralExpression(this.token, {required this.value});

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitLiteral(this);
}

/// An expression representing property access using dot notation.
///
/// Represents accessing a property or method of an object,
/// such as `{{ user.name }}` or `{{ text.toUpperCase }}`.
/// The expression consists of the object being accessed,
/// the dot token, and the property identifier.
@immutable
final class PropertyAccessExpression extends Expression {
  /// The expression representing the object being accessed.
  final Expression object;

  /// The dot token (for source location tracking).
  final Token dotToken;

  /// The token containing the property name.
  final Token identifier;

  /// Creates a property access expression.
  ///
  /// [object] is the expression being accessed,
  /// [dotToken] is the dot separator, and [identifier] is the property name.
  const PropertyAccessExpression(this.object, this.dotToken, this.identifier);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) =>
      visitor.visitPropertyAccess(this);
}

/// An expression representing index access using bracket notation.
///
/// Represents accessing an element by index or key,
/// such as `{{ users[0] }}` or `{{ data['key'] }}`.
/// The expression consists of the object being indexed,
/// the bracket tokens, and the index expression.
@immutable
final class IndexAccessExpression extends Expression {
  /// The expression representing the object being indexed.
  final Expression object;

  /// The opening bracket token (for source location tracking).
  final Token leftBracketToken;

  /// The expression representing the index or key.
  final Expression index;

  /// The closing bracket token (for source location tracking).
  final Token rightBracketToken;

  /// Creates an index access expression.
  ///
  /// [object] is the expression being indexed,
  /// [leftBracketToken] and [rightBracketToken] are the bracket delimiters,
  /// and [index] is the key or index expression.
  const IndexAccessExpression(
    this.object,
    this.leftBracketToken,
    this.index,
    this.rightBracketToken,
  );

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitIndexAccess(this);
}

/// An expression representing a function or method call.
///
/// Represents calling a function or method with optional arguments,
/// such as `{{ getName() }}`, `{{ format('Hello', name: 'World') }}`, or
/// `{{ text.substring(0, end: 10) }}`. The expression supports both
/// positional and named arguments in flexible order.
@immutable
final class CallExpression extends Expression {
  /// The expression representing the function or method being called.
  final Expression callee;

  /// The opening parenthesis token (for source location tracking).
  final Token leftParenToken;

  /// The list of positional arguments.
  final List<Expression> positionalArguments;

  /// The map of named arguments (parameter name to expression).
  final Map<String, Expression> namedArguments;

  /// The closing parenthesis token (for source location tracking).
  final Token rightParenToken;

  /// Creates a function call expression.
  ///
  /// [callee] is the function being called,
  /// [leftParenToken] and [rightParenToken] are the parenthesis delimiters,
  /// [positionalArguments] contains the positional parameters, and
  /// [namedArguments] contains the named parameters.
  const CallExpression(
    this.callee,
    this.leftParenToken,
    this.positionalArguments,
    this.namedArguments,
    this.rightParenToken,
  );

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitCall(this);
}
