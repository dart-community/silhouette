import 'package:meta/meta.dart';

import 'parser.dart';
import 'template.dart';
import 'value.dart';

/// Template engine for compiling and rendering Silhouette templates.
///
/// Example usage:
///
/// ```dart
/// // Create engine with global variables.
/// final engine = TemplateEngine(globals: SilhouetteObject({
///   SilhouetteIdentifier('siteName'): SilhouetteString('The Website'),
///   SilhouetteIdentifier('currentYear'): SilhouetteInt(2025),
/// }));
///
/// // Compile and render a template directly.
/// final result = await engine.compile(
///   'Welcome to {{ siteName }} {{ username }}! Copyright {{ currentYear }}.',
/// ).render(
///   SilhouetteObject({
///     SilhouetteIdentifier('username'): SilhouetteString('Dash'),
///   }),
/// );
///
/// // Or compile once and render multiple times.
/// final compiled = engine.compile('Hello {{ name }}!');
///
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
final class TemplateEngine {
  /// Default global variables available to all templates.
  ///
  /// Currently empty but reserved for future built-in functions and
  /// constants that should be available in all template contexts.
  static const SilhouetteObject _defaultGlobals = SilhouetteObject({});

  /// Global variables available to all templates compiled by this engine.
  final SilhouetteObject _globals;

  /// Creates a new template engine with the specified [globals]
  /// to make available when rendering templates compiled by this engine.
  ///
  /// When there are naming collisions,
  /// template-specific context variables take precedence over [globals].
  ///
  /// If [includeDefaultGlobals] is `true`, which is the default value,
  /// built-in values are included at the top level.
  /// If you want complete control over the global namespace, set to `false`.
  ///
  /// Example:
  ///
  /// ```dart
  /// final engine = TemplateEngine(
  ///   globals: SilhouetteObject({
  ///     SilhouetteIdentifier('version'): SilhouetteString('1.0.0'),
  ///     SilhouetteIdentifier('debug'): SilhouetteBool(true),
  ///   }),
  ///   includeDefaultGlobals: true,
  /// );
  /// ```
  TemplateEngine({
    SilhouetteObject globals = const SilhouetteObject({}),
    bool includeDefaultGlobals = true,
  }) : _globals = SilhouetteObject({
         if (includeDefaultGlobals) ..._defaultGlobals.value,
         ...globals.value,
       });

  /// Compiles a template string into a [CompiledTemplate].
  ///
  /// Compiled templates can be rendered multiple times with different
  /// context data for better performance than re-compiling each time.
  ///
  /// The [template] string should contain valid Silhouette template syntax.
  ///
  /// If the template contains invalid syntax, an exception is thrown.
  ///
  /// Example:
  ///
  /// ```dart
  /// final compiled = engine.compile('Hello {{ name.toUpperCase() }}!');
  /// ```
  @useResult
  CompiledTemplate compile(String template) {
    // Parse/compile the template.
    final parser = Parser(template);
    final statements = parser.parse();

    return CompiledTemplate(statements, _globals);
  }
}
