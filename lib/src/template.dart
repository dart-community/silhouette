import 'package:meta/meta.dart';

import 'ast.dart';
import 'renderer.dart';
import 'value.dart';

/// A compiled template that can be rendered multiple times with different data.
///
/// Compiled templates provide better performance for repeated rendering since
/// the parsing phase is done once during compilation.
///
/// Example usage:
///
/// ```dart
/// final engine = TemplateEngine();
/// final compiled = engine.compile('Hello {{ name }}!');
///
/// // Render multiple times with different data.
/// final worldResult = await compiled.render(
///   SilhouetteObject({
///     SilhouetteIdentifier('name'): SilhouetteString('World'),
///   }),
/// );
/// final dashResult = await compiled.render(
///   SilhouetteObject({
///     SilhouetteIdentifier('name'): SilhouetteString('Dash'),
///   }),
/// );
/// ```
@immutable
final class CompiledTemplate {
  /// The parsed AST statement representing the template structure.
  final Statement _statement;

  /// Global variables available to this template.
  final SilhouetteObject _globals;

  /// Creates a compiled template with the given [_statement] and [_globals].
  @internal
  const CompiledTemplate(this._statement, this._globals);

  /// Renders the template into a string with the given top-level [context]
  /// and any global values defined from the engine that compiled this template.
  @useResult
  Future<String> render([SilhouetteObject? context]) {
    final evaluator = TemplateRenderer(_globals);
    return evaluator.evaluate(_statement, context);
  }
}
