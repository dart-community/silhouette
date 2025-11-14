import 'package:silhouette/silhouette.dart';
import 'package:test/test.dart';

void main() {
  group('Named arguments', () {
    late TemplateEngine engine;

    setUp(() {
      engine = TemplateEngine(
        globals: SilhouetteObject({
          SilhouetteIdentifier('format'): SilhouetteFunction((args) {
            final value = args.positional.isNotEmpty
                ? args.positional[0]
                : const SilhouetteString('');
            final pattern =
                args.named['pattern'] ?? const SilhouetteString('{}');

            if (value is! SilhouetteString || pattern is! SilhouetteString) {
              throw const SilhouetteException('Arguments must be strings');
            }

            return SilhouetteString(
              pattern.value.replaceFirst('{}', value.value),
            );
          }),
        }),
      );
    });

    group('Built-in functions', () {
      test('format function with named arguments', () async {
        final compiledTemplate = engine.compile(
          '{{ format(name, pattern: "Hello, {}!") }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('World'),
          }),
        );
        expect(result, 'Hello, World!');
      });

      test('format function with default pattern', () async {
        final compiledTemplate = engine.compile(
          '{{ format(name) }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Test'),
          }),
        );
        expect(result, 'Test');
      });
    });

    group('String methods', () {
      test('substring with named end parameter', () async {
        final compiledTemplate = engine.compile(
          '{{ text.substring(2, end: 5) }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello World'),
          }),
        );
        expect(result, 'llo');
      });

      test('substring without end parameter', () async {
        final compiledTemplate = engine.compile(
          '{{ text.substring(6) }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello World'),
          }),
        );
        expect(result, 'World');
      });

      test('replace with all parameter set to false', () async {
        final compiledTemplate = engine.compile(
          '{{ text.replace("l", "X", all: false) }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello'),
          }),
        );
        expect(result, 'HeXlo');
      });

      test('replace with all parameter set to true (default)', () async {
        final compiledTemplate = engine.compile(
          '{{ text.replace("l", "X") }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello'),
          }),
        );
        expect(result, 'HeXXo');
      });

      test('replace with explicit all parameter set to true', () async {
        final compiledTemplate = engine.compile(
          '{{ text.replace("l", "X", all: true) }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello'),
          }),
        );
        expect(result, 'HeXXo');
      });
    });

    group('List methods', () {
      test('join with positional separator parameter', () async {
        final compiledTemplate = engine.compile(
          '{{ items.join(" | ") }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('apple'),
              SilhouetteString('banana'),
              SilhouetteString('cherry'),
            ]),
          }),
        );
        expect(result, 'apple | banana | cherry');
      });

      test('join with default separator', () async {
        final compiledTemplate = engine.compile(
          '{{ items.join() }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
            ]),
          }),
        );
        expect(result, 'abc');
      });
    });

    group('Mixed arguments', () {
      test('function with mixed positional and named arguments', () async {
        final compiledTemplate = engine.compile(
          '{{ format(name, pattern: "Welcome {}!") }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Alice'),
          }),
        );
        expect(result, 'Welcome Alice!');
      });

      test('method with mixed arguments in any order', () async {
        final compiledTemplate = engine.compile(
          '{{ text.replace("old", all: false, "new") }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString(
              'old old text',
            ),
          }),
        );
        expect(result, 'new old text');
      });
    });

    group('Custom functions with named arguments', () {
      test('register custom function supporting named arguments', () async {
        final customEngine = TemplateEngine(
          globals: SilhouetteObject({
            SilhouetteIdentifier('greet'): SilhouetteFunction((args) {
              final name = args.positional.isNotEmpty
                  ? args.positional[0]
                  : const SilhouetteString('World');
              final greeting =
                  args.named['greeting'] ?? const SilhouetteString('Hello');
              final punctuation =
                  args.named['punctuation'] ?? const SilhouetteString('!');

              if (name is! SilhouetteString) {
                throw const SilhouetteException('Name must be a string');
              }
              if (greeting is! SilhouetteString) {
                throw const SilhouetteException('Greeting must be a string');
              }
              if (punctuation is! SilhouetteString) {
                throw const SilhouetteException('Punctuation must be a string');
              }

              return SilhouetteString(
                '${greeting.value} ${name.value}${punctuation.value}',
              );
            }),
          }),
        );

        final compiledTemplate = customEngine.compile(
          '{{ greet("Alice", greeting: "Hi", punctuation: ".") }}',
        );
        final result = await compiledTemplate.render(
          const SilhouetteObject({}),
        );
        expect(result, 'Hi Alice.');
      });

      test('custom function with only named arguments', () async {
        final customEngine = TemplateEngine(
          globals: SilhouetteObject({
            SilhouetteIdentifier('createMessage'): SilhouetteFunction((
              args,
            ) {
              final message =
                  args.named['message'] ?? const SilhouetteString('Default');
              final type = args.named['type'] ?? const SilhouetteString('info');

              if (message is! SilhouetteString || type is! SilhouetteString) {
                throw const SilhouetteException(
                  'All arguments must be strings',
                );
              }

              return SilhouetteString(
                '[${type.value.toUpperCase()}] ${message.value}',
              );
            }),
          }),
        );

        final compiledTemplate = customEngine.compile(
          '{{ createMessage(message: "System ready", type: "success") }}',
        );
        final result = await compiledTemplate.render(
          const SilhouetteObject({}),
        );
        expect(result, '[SUCCESS] System ready');
      });
    });

    group('Error cases', () {
      test('throws error for incorrect named argument types', () {
        expect(
          () {
            final compiledTemplate = engine.compile(
              '{{ text.replace("old", "new", all: "invalid") }}',
            );
            return compiledTemplate.render(
              SilhouetteObject({
                SilhouetteIdentifier('text'): const SilhouetteString(
                  'old text',
                ),
              }),
            );
          },
          throwsA(isA<SilhouetteException>()),
        );
      });

      test('handles missing optional named arguments gracefully', () async {
        final compiledTemplate = engine.compile(
          '{{ format(value) }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('test'),
          }),
        );
        expect(result, 'test');
      });
    });

    group('Complex expressions', () {
      test('chained methods with named arguments', () async {
        final compiledTemplate = engine.compile(
          '{{ text.substring(0, end: 5).replace("l", "X", all: false) }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello World'),
          }),
        );
        expect(result, 'HeXlo');
      });

      test('nested function calls with named arguments', () async {
        final compiledTemplate = engine.compile(
          '{{ format(text.substring(0, end: 5), pattern: "[{}]") }}',
        );
        final result = await compiledTemplate.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello World'),
          }),
        );
        expect(result, '[Hello]');
      });
    });
  });
}
