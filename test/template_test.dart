import 'package:silhouette/silhouette.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateEngine', () {
    late TemplateEngine engine;

    setUp(() {
      engine = TemplateEngine();
    });

    group('Basic rendering', () {
      test('renders plain text', () async {
        final compiled = engine.compile('Hello World');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Hello World');
      });

      test('renders empty template', () async {
        final compiled = engine.compile('');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, '');
      });

      test('renders template with empty tags', () async {
        final compiled = engine.compile('{{}}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, '');
      });

      test('renders simple variable', () async {
        final compiled = engine.compile('Hello {{ name }}!');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Alice'),
          }),
        );
        expect(result, 'Hello Alice!');
      });

      test('renders multiple variables', () async {
        final compiled = engine.compile('{{ greeting }}, {{ name }}!');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('greeting'): const SilhouetteString('Hello'),
            SilhouetteIdentifier('name'): const SilhouetteString('Bob'),
          }),
        );
        expect(result, 'Hello, Bob!');
      });

      test('renders mixed text and variables', () async {
        final compiled = engine.compile('Name: {{ name }}, Age: {{ age }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Charlie'),
            SilhouetteIdentifier('age'): const SilhouetteInt(25),
          }),
        );
        expect(result, 'Name: Charlie, Age: 25');
      });
    });

    group('Property access', () {
      test('accesses object properties', () async {
        final compiled = engine.compile('{{ user.name }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('user'): SilhouetteObject({
              SilhouetteIdentifier('name'): const SilhouetteString('David'),
            }),
          }),
        );
        expect(result, 'David');
      });

      test('accesses nested properties', () async {
        final compiled = engine.compile('{{ company.department.manager }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('company'): SilhouetteObject({
              SilhouetteIdentifier('department'): SilhouetteObject({
                SilhouetteIdentifier('manager'): const SilhouetteString('Eve'),
              }),
            }),
          }),
        );
        expect(result, 'Eve');
      });

      test('accesses string properties', () async {
        final compiled = engine.compile(
          'Length: {{ text.length }}, Empty: {{ text.isEmpty }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello'),
          }),
        );
        expect(result, 'Length: 5, Empty: false');
      });

      test('accesses list properties', () async {
        final compiled = engine.compile(
          'First: {{ items.first }}, Last: {{ items.last }}, '
          'Count: {{ items.length }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteInt(1),
              SilhouetteInt(2),
              SilhouetteInt(3),
            ]),
          }),
        );
        expect(result, 'First: 1, Last: 3, Count: 3');
      });
    });

    group('Index access', () {
      test('accesses list by index', () async {
        final compiled = engine.compile('{{ items[1] }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
            ]),
          }),
        );
        expect(result, 'b');
      });

      test('accesses data by key', () async {
        final compiled = engine.compile('{{ config["host"] }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('config'): SilhouetteObject({
              SilhouetteIdentifier('host'): const SilhouetteString('localhost'),
              SilhouetteIdentifier('port'): const SilhouetteInt(8080),
            }),
          }),
        );
        expect(result, 'localhost');
      });

      test('accesses nested structures', () async {
        final compiled = engine.compile('{{ data["users"][0]["name"] }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('data'): SilhouetteObject({
              SilhouetteIdentifier('users'): SilhouetteList([
                SilhouetteObject({
                  SilhouetteIdentifier('name'): const SilhouetteString('Frank'),
                }),
                SilhouetteObject({
                  SilhouetteIdentifier('name'): const SilhouetteString('Grace'),
                }),
              ]),
            }),
          }),
        );
        expect(result, 'Frank');
      });
    });

    group('Method calls', () {
      test('calls string methods', () async {
        final compiled = engine.compile(
          '{{ text.toUpperCase }}, {{ text.substring(0) }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('hello'),
          }),
        );
        expect(result, 'HELLO, hello');
      });

      test('calls string methods with arguments', () async {
        final compiled = engine.compile('{{ text.substring(0, end: 3) }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('hello'),
          }),
        );
        expect(result, 'hel');
      });

      test('calls list methods', () async {
        final compiled = engine.compile('{{ items.join(" ") }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
            ]),
          }),
        );
        expect(result, 'a b c');
      });

      test('calls string replace method', () async {
        final compiled = engine.compile('{{ text.replace("hello", "hi") }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('hello world'),
          }),
        );
        expect(result, 'hi world');
      });

      test('calls string trim method', () async {
        final compiled = engine.compile('{{ text.trim() }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString(
              '  hello world  ',
            ),
          }),
        );
        expect(result, 'hello world');
      });
    });

    group('Function calls', () {
      test('calls custom functions', () async {
        final customEngine = TemplateEngine(
          globals: SilhouetteObject({
            SilhouetteIdentifier('greet'): SilhouetteFunction((args) {
              final name = args.positional.isNotEmpty
                  ? args.positional[0]
                  : const SilhouetteString('World');
              return SilhouetteString('Hello, $name!');
            }),
            SilhouetteIdentifier('add'): SilhouetteFunction((args) {
              if (args.positional.length < 2) {
                throw const SilhouetteException('add() requires 2 arguments');
              }
              final a = args.positional[0];
              final b = args.positional[1];
              if (a is SilhouetteInt && b is SilhouetteInt) {
                return SilhouetteInt(a.value + b.value);
              }
              throw const SilhouetteException('add() requires two integers');
            }),
          }),
        );

        final compiled = customEngine.compile(
          '{{ greet(name) }}, {{ add(x, y) }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Henry'),
            SilhouetteIdentifier('x'): const SilhouetteInt(10),
            SilhouetteIdentifier('y'): const SilhouetteInt(20),
          }),
        );
        expect(result, 'Hello, Henry!, 30');
      });
    });

    group('Literal values', () {
      test('renders string literals', () async {
        final compiled = engine.compile('{{ "Hello" }} {{ \'World\' }}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Hello World');
      });

      test('renders number literals', () async {
        final compiled = engine.compile('{{ 42 }} {{ 3.14 }}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, '42 3.14');
      });

      test('renders negative number literals', () async {
        final compiled = engine.compile('{{ -42 }} {{ -3.14 }} {{ -0 }}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, '-42 -3.14 0');
      });

      test('renders boolean literals', () async {
        final compiled = engine.compile('{{ true }} {{ false }}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'true false');
      });

      test('renders null literal', () async {
        final compiled = engine.compile('Value: {{ null }}!');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Value: null!');
      });
    });

    group('Complex templates', () {
      test('renders HTML template with data', () async {
        const template = '''
<div>
  <h1>{{ user.name }}</h1>
  <p>Email: {{ user.email }}</p>
  <ul>
    <li>Skills: {{ user.skills.join(", ") }}</li>
    <li>Experience: {{ user.experience }} years</li>
  </ul>
</div>''';

        final compiled = engine.compile(template);
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('user'): SilhouetteObject({
              SilhouetteIdentifier('name'): const SilhouetteString(
                'Ivy Johnson',
              ),
              SilhouetteIdentifier('email'): const SilhouetteString(
                'ivy@example.com',
              ),
              SilhouetteIdentifier('skills'): const SilhouetteList([
                SilhouetteString('JavaScript'),
                SilhouetteString('Python'),
                SilhouetteString('Dart'),
              ]),
              SilhouetteIdentifier('experience'): const SilhouetteInt(5),
            }),
          }),
        );

        expect(result, '''
<div>
  <h1>Ivy Johnson</h1>
  <p>Email: ivy@example.com</p>
  <ul>
    <li>Skills: JavaScript, Python, Dart</li>
    <li>Experience: 5 years</li>
  </ul>
</div>''');
      });

      test('renders complex expression chains', () async {
        final compiled = engine.compile(
          '{{ users[0]["addresses"][0]["city"].toUpperCase }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('users'): SilhouetteList([
              SilhouetteObject({
                SilhouetteIdentifier('addresses'): SilhouetteList([
                  SilhouetteObject({
                    SilhouetteIdentifier('city'): const SilhouetteString(
                      'new york',
                    ),
                  }),
                ]),
              }),
            ]),
          }),
        );
        expect(result, 'NEW YORK');
      });
    });

    group('Error handling', () {
      test('throws on undefined variables', () {
        expect(
          () async {
            final compiled = engine.compile('Hello {{ name }}!');
            return await compiled.render(const SilhouetteObject({}));
          }(),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on null property access', () {
        expect(
          () async {
            final compiled = engine.compile('{{ user.name }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('user'): SilhouetteNull(),
              }),
            );
          }(),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on invalid property access', () {
        expect(
          () async {
            final compiled = engine.compile('{{ text.unknownProperty }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('text'): const SilhouetteString('hello'),
              }),
            );
          }(),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on invalid function calls', () {
        expect(
          () async {
            final compiled = engine.compile('{{ unknownFunction() }}');
            return await compiled.render(const SilhouetteObject({}));
          }(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Specific exception types', () {
      test('throws UnknownPropertyException for invalid property access', () {
        expect(
          () async {
            final compiled = engine.compile('{{ text.unknownProperty }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('text'): const SilhouetteString('hello'),
              }),
            );
          }(),
          throwsA(isA<UnknownPropertyException>()),
        );
      });

      test('throws UnknownKeyException for invalid list index', () {
        expect(
          () async {
            final compiled = engine.compile('{{ items[99] }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('items'): const SilhouetteList([
                  SilhouetteString('hello'),
                ]),
              }),
            );
          }(),
          throwsA(isA<UnknownKeyException>()),
        );
      });

      test('throws UnknownKeyException for invalid map key', () {
        expect(
          () async {
            final compiled = engine.compile('{{ data["missing"] }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('data'): SilhouetteMap({
                  const SilhouetteString('existing'): const SilhouetteString(
                    'value',
                  ),
                }),
              }),
            );
          }(),
          throwsA(isA<UnknownKeyException>()),
        );
      });

      test('throws UnknownPropertyException for invalid method call', () {
        expect(
          () async {
            final compiled = engine.compile('{{ text.unknownMethod() }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('text'): const SilhouetteString('hello'),
              }),
            );
          }(),
          throwsA(isA<UnknownPropertyException>()),
        );
      });
    });

    group('Template compilation', () {
      test('compiles and reuses templates', () async {
        final compiled = engine.compile('Hello {{ name }}!');

        final result1 = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Jack'),
          }),
        );
        expect(result1, 'Hello Jack!');

        final result2 = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Kate'),
          }),
        );
        expect(result2, 'Hello Kate!');
      });
    });

    group('List operations', () {
      test('accesses list elements', () async {
        final compiled = engine.compile(
          'First: {{ items.first }}, Last: {{ items.last }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
            ]),
          }),
        );
        expect(result, 'First: a, Last: c');
      });

      test('joins list elements', () async {
        final compiled = engine.compile('{{ items.join(" - ") }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('apple'),
              SilhouetteString('banana'),
              SilhouetteString('cherry'),
            ]),
          }),
        );
        expect(result, 'apple - banana - cherry');
      });

      test('reverses list', () async {
        final compiled = engine.compile('{{ items.reverse().join(" ") }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
            ]),
          }),
        );
        expect(result, 'c b a');
      });

      test('slices list', () async {
        final compiled = engine.compile(
          '{{ items.slice(start: 1, end: 3).join(" ") }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
              SilhouetteString('d'),
            ]),
          }),
        );
        expect(result, 'b c');
      });
    });

    group('String operations', () {
      test('checks string properties', () async {
        final compiled = engine.compile(
          'Empty: {{ empty.isEmpty }}, Not Empty: {{ text.isNotEmpty }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('empty'): const SilhouetteString(''),
            SilhouetteIdentifier('text'): const SilhouetteString('hello'),
          }),
        );
        expect(result, 'Empty: true, Not Empty: true');
      });

      test('splits strings', () async {
        final compiled = engine.compile('{{ text.split(" ").join(" | ") }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString(
              'hello world test',
            ),
          }),
        );
        expect(result, 'hello | world | test');
      });

      test('checks string contains', () async {
        final compiled = engine.compile(
          'Contains: {{ text.contains("world") }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('hello world'),
          }),
        );
        expect(result, 'Contains: true');
      });

      test('checks string starts/ends with', () async {
        final compiled = engine.compile(
          'Starts: {{ text.startsWith("hello") }}, '
          'Ends: {{ text.endsWith("world") }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('hello world'),
          }),
        );
        expect(result, 'Starts: true, Ends: true');
      });
    });

    group('Number properties', () {
      test('checks integer properties', () async {
        final compiled = engine.compile(
          'Even: {{ num.isEven }}, Odd: {{ num.isOdd }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('num'): const SilhouetteInt(4),
          }),
        );
        expect(result, 'Even: true, Odd: false');
      });

      test('calls integer numeric methods', () async {
        final compiled = engine.compile(
          'Abs: {{ negNum.abs() }}, Fixed: {{ num.toStringAsFixed(2) }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('negNum'): const SilhouetteInt(-42),
            SilhouetteIdentifier('num'): const SilhouetteInt(123),
          }),
        );
        expect(result, 'Abs: 42, Fixed: 123.00');
      });

      test('calls double numeric methods', () async {
        final compiled = engine.compile(
          'Abs: {{ negNum.abs() }}, Round: {{ pi.round() }}, '
          'Floor: {{ pi.floor() }}, Ceil: {{ pi.ceil() }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('negNum'): const SilhouetteDouble(-3.14),
            SilhouetteIdentifier('pi'): const SilhouetteDouble(3.14),
          }),
        );
        expect(result, 'Abs: 3.14, Round: 3, Floor: 3, Ceil: 4');
      });

      test('calls toStringAsFixed on double', () async {
        final compiled = engine.compile(
          'Formatted: {{ pi.toStringAsFixed(2) }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('pi'): const SilhouetteDouble(3.14159),
          }),
        );
        expect(result, 'Formatted: 3.14');
      });

      test('handles numeric method errors', () {
        expect(
          () async {
            final compiled = engine.compile('{{ num.toStringAsFixed() }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('num'): const SilhouetteInt(42),
              }),
            );
          }(),
          throwsA(isA<SilhouetteException>()),
        );
      });
    });

    group('Edge cases', () {
      test('handles empty lists gracefully', () async {
        final compiled = engine.compile(
          'Length: {{ items.length }}, Empty: {{ items.isEmpty }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'):
                const SilhouetteList<SilhouetteString>([]),
          }),
        );
        expect(result, 'Length: 0, Empty: true');
      });

      test('handles list access out of bounds', () {
        expect(
          () async {
            final compiled = engine.compile('{{ items[5] }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('items'): const SilhouetteList([
                  SilhouetteString('a'),
                ]),
              }),
            );
          }(),
          throwsA(isA<Exception>()),
        );
      });

      test('handles data access for missing keys', () {
        expect(
          () async {
            final compiled = engine.compile('{{ data.missing }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('data'): SilhouetteObject({
                  SilhouetteIdentifier('present'): const SilhouetteString(
                    'value',
                  ),
                }),
              }),
            );
          }(),
          throwsA(isA<Exception>()),
        );
      });

      test('handles mixed numeric types in context', () async {
        final compiled = engine.compile(
          'Int: {{ intVal }}, Double: {{ doubleVal }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('intVal'): const SilhouetteInt(42),
            SilhouetteIdentifier('doubleVal'): const SilhouetteDouble(3.14),
          }),
        );
        expect(result, 'Int: 42, Double: 3.14');
      });

      test('handles boolean values in context', () async {
        final compiled = engine.compile(
          'True: {{ trueVal }}, False: {{ falseVal }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('trueVal'): const SilhouetteBool(true),
            SilhouetteIdentifier('falseVal'): const SilhouetteBool(false),
          }),
        );
        expect(result, 'True: true, False: false');
      });

      test('handles null values in context', () async {
        final compiled = engine.compile('Null: {{ nullVal }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('nullVal'): SilhouetteNull(),
          }),
        );
        expect(result, 'Null: null');
      });
    });

    group('Advanced string operations', () {
      test('handles string replacement with options', () async {
        final compiled = engine.compile(
          'Replace first: {{ text.replace("o", "X", all: false) }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('hello world'),
          }),
        );
        expect(result, 'Replace first: hellX world');
      });

      test('handles string contains with different cases', () async {
        final compiled = engine.compile(
          'Contains Hello: {{ text.contains("Hello") }}, '
          'contains hello: {{ text.contains("hello") }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('text'): const SilhouetteString('Hello World'),
          }),
        );
        expect(result, 'Contains Hello: true, contains hello: false');
      });
    });

    group('Advanced list operations', () {
      test('handles list contains check', () async {
        final compiled = engine.compile(
          'Contains B: {{ items.contains("b") }}, '
          'Contains X: {{ items.contains("x") }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
            ]),
          }),
        );
        expect(result, 'Contains B: true, Contains X: false');
      });

      test('handles list slice with just start parameter', () async {
        final compiled = engine.compile(
          '{{ items.slice(start: 1).join(" ") }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('a'),
              SilhouetteString('b'),
              SilhouetteString('c'),
              SilhouetteString('d'),
            ]),
          }),
        );
        expect(result, 'b c d');
      });

      test('handles empty list operations', () {
        const items = SilhouetteList<SilhouetteString>([]);

        expect(
          () async {
            final compiled = engine.compile('{{ items.first }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('items'): items,
              }),
            );
          }(),
          throwsA(isA<Exception>()),
        );

        expect(
          () async {
            final compiled = engine.compile('{{ items.last }}');
            return await compiled.render(
              SilhouetteObject({
                SilhouetteIdentifier('items'): items,
              }),
            );
          }(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Complex nested access', () {
      test('handles deeply nested property access', () async {
        final compiled = engine.compile(
          '{{ root.level1.level2.level3.value }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('root'): SilhouetteObject({
              SilhouetteIdentifier('level1'): SilhouetteObject({
                SilhouetteIdentifier('level2'): SilhouetteObject({
                  SilhouetteIdentifier('level3'): SilhouetteObject({
                    SilhouetteIdentifier('value'): const SilhouetteString(
                      'deep',
                    ),
                  }),
                }),
              }),
            }),
          }),
        );
        expect(result, 'deep');
      });

      test('handles mixed property and index access', () async {
        final compiled = engine.compile('{{ data["items"][0].name }}');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('data'): SilhouetteObject({
              SilhouetteIdentifier('items'): SilhouetteList([
                SilhouetteObject({
                  SilhouetteIdentifier('name'): const SilhouetteString('first'),
                }),
                SilhouetteObject({
                  SilhouetteIdentifier('name'): const SilhouetteString(
                    'second',
                  ),
                }),
              ]),
            }),
          }),
        );
        expect(result, 'first');
      });
    });

    group('Whitespace trimming', () {
      test('trims leading whitespace with {{-', () async {
        final compiled = engine.compile('Before   {{- name }}After');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('TEST'),
          }),
        );
        expect(result, 'BeforeTESTAfter');
      });

      test('trims trailing whitespace with -}}', () async {
        final compiled = engine.compile('Before{{ name -}}   After');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('TEST'),
          }),
        );
        expect(result, 'BeforeTESTAfter');
      });

      test('trims both sides with {{- -}}', () async {
        final compiled = engine.compile('Before   {{- name -}}   After');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('TEST'),
          }),
        );
        expect(result, 'BeforeTESTAfter');
      });

      test('handles newlines and tabs in trimming', () async {
        final compiled = engine.compile('Line1\n\t  {{- name -}}  \n\tLine2');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('MIDDLE'),
          }),
        );
        expect(result, 'Line1MIDDLELine2');
      });

      test('trims multiple consecutive whitespace characters', () async {
        final compiled = engine.compile('Start     {{- value -}}     End');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('X'),
          }),
        );
        expect(result, 'StartXEnd');
      });

      test('handles trimming at template boundaries', () async {
        final compiled1 = engine.compile('   {{- name }}');
        final result1 = await compiled1.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('START'),
          }),
        );
        expect(result1, 'START');

        final compiled2 = engine.compile('{{ name -}}   ');
        final result2 = await compiled2.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('END'),
          }),
        );
        expect(result2, 'END');
      });

      test('preserves whitespace without trimming modifiers', () async {
        final compiled = engine.compile('Before   {{ name }}   After');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('TEST'),
          }),
        );
        expect(result, 'Before   TEST   After');
      });

      test('handles mixed trimmed and non-trimmed tags', () async {
        final compiled = engine.compile('A {{- x }} B {{ y -}} C {{- z -}} D');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('x'): const SilhouetteString('1'),
            SilhouetteIdentifier('y'): const SilhouetteString('2'),
            SilhouetteIdentifier('z'): const SilhouetteString('3'),
          }),
        );
        expect(result, 'A1 B 2C3D');
      });

      test('handles empty expressions with trimming', () async {
        final compiled = engine.compile('Before   {{-  -}}   After');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'BeforeAfter');
      });

      test('handles consecutive trimmed tags', () async {
        final compiled = engine.compile(
          'Start {{- a -}} {{- b -}} {{- c -}} End',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('a'): const SilhouetteString('1'),
            SilhouetteIdentifier('b'): const SilhouetteString('2'),
            SilhouetteIdentifier('c'): const SilhouetteString('3'),
          }),
        );
        expect(result, 'Start123End');
      });

      test('handles carriage return and mixed line endings', () async {
        final compiled = engine.compile('Line1\r\n  {{- value -}}  \r\nLine2');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('MID'),
          }),
        );
        expect(result, 'Line1MIDLine2');
      });

      test('trims only specified sides', () async {
        final compiled = engine.compile(
          '  Left{{- onlyLeft }}  Right{{ onlyRight -}}  Both  ',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('onlyLeft'): const SilhouetteString('L'),
            SilhouetteIdentifier('onlyRight'): const SilhouetteString('R'),
          }),
        );
        expect(result, '  LeftL  RightRBoth  ');
      });

      test('handles whitespace with complex expressions', () async {
        final compiled = engine.compile(
          'Value:   {{- user.name.trim() -}}   Done',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('user'): SilhouetteObject({
              SilhouetteIdentifier('name'): const SilhouetteString('  alice  '),
            }),
          }),
        );
        expect(result, 'Value:aliceDone');
      });

      test('handles whitespace with method calls and indexing', () async {
        final compiled = engine.compile(
          'Items: {{- items[0].trim() -}} and {{- items[1] -}}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('  first  '),
              SilhouetteString('second'),
            ]),
          }),
        );
        expect(result, 'Items:firstandsecond');
      });

      test('preserves internal expression whitespace', () async {
        final compiled = engine.compile(
          'Result: {{- user[ "full name" ] -}}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('user'): SilhouetteMap({
              const SilhouetteString('full name'): const SilhouetteString(
                'John Doe',
              ),
            }),
          }),
        );
        expect(result, 'Result:John Doe');
      });

      test('handles only whitespace between trimmed tags', () async {
        final compiled = engine.compile('A{{- x -}}   {{- y -}}B');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('x'): const SilhouetteString('1'),
            SilhouetteIdentifier('y'): const SilhouetteString('2'),
          }),
        );
        expect(result, 'A12B');
      });

      test('handles multiple newlines with trimming', () async {
        final compiled = engine.compile('Start\n\n\n{{- value -}}\n\n\nEnd');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('MIDDLE'),
          }),
        );
        expect(result, 'StartMIDDLEEnd');
      });

      test('handles tabs only with trimming', () async {
        final compiled = engine.compile('Before\t\t{{- name -}}\t\tAfter');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('TAB'),
          }),
        );
        expect(result, 'BeforeTABAfter');
      });

      test('handles mixed whitespace types', () async {
        final compiled = engine.compile(
          'Start \t\n\r {{- value -}} \n\t\r End',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('MIX'),
          }),
        );
        expect(result, 'StartMIXEnd');
      });

      test('handles trimming with string literals', () async {
        final compiled = engine.compile('Quote:  {{- "Hello World" -}}  End');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Quote:Hello WorldEnd');
      });

      test('handles trimming with numeric literals', () async {
        final compiled = engine.compile(
          'Numbers: {{- 42 -}} and {{- 3.14 -}} done',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Numbers:42and3.14done');
      });

      test('handles trimming with boolean literals', () async {
        final compiled = engine.compile('Bool: {{- true -}} {{- false -}} end');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Bool:truefalseend');
      });

      test('handles trimming with null literal', () async {
        final compiled = engine.compile('Null: {{- null -}} done');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Null:nulldone');
      });

      test('handles asymmetric trimming combinations', () async {
        final compiled = engine.compile(
          ' A {{- b }} C {{ d -}} E {{- f -}} G ',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('b'): const SilhouetteString('B'),
            SilhouetteIdentifier('d'): const SilhouetteString('D'),
            SilhouetteIdentifier('f'): const SilhouetteString('F'),
          }),
        );
        expect(result, ' AB C DEFG ');
      });

      test(
        'preserves whitespace inside string literals with trimming',
        () async {
          final compiled = engine.compile('Text:{{- "  spaced text  " -}}End');
          final result = await compiled.render(const SilhouetteObject({}));
          expect(result, 'Text:  spaced text  End');
        },
      );

      test('handles trimming with very long whitespace sequences', () async {
        const whitespace = '          \n\n\n\t\t\t          ';
        final compiled = engine.compile(
          'Before$whitespace{{- value -}}${whitespace}After',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('CENTER'),
          }),
        );
        expect(result, 'BeforeCENTERAfter');
      });

      test('handles trimming at template start only', () async {
        final compiled = engine.compile('   {{- start }}middle{{ end }}   ');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('start'): const SilhouetteString('S'),
            SilhouetteIdentifier('end'): const SilhouetteString('E'),
          }),
        );
        expect(result, 'SmiddleE   ');
      });

      test('handles trimming at template end only', () async {
        final compiled = engine.compile('   {{ start }}middle{{ end -}}   ');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('start'): const SilhouetteString('S'),
            SilhouetteIdentifier('end'): const SilhouetteString('E'),
          }),
        );
        expect(result, '   SmiddleE');
      });

      test('handles minus in string literals', () async {
        final compiled = engine.compile('Text: {{ "5-2=3" }}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Text: 5-2=3');
      });

      test('handles empty template with only trimming tags', () async {
        final compiled = engine.compile('{{- -}}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, '');
      });

      test('handles nested data access with trimming', () async {
        final compiled = engine.compile(
          'Deep:{{- data.user.profile.name -}}End',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('data'): SilhouetteObject({
              SilhouetteIdentifier('user'): SilhouetteObject({
                SilhouetteIdentifier('profile'): SilhouetteObject({
                  SilhouetteIdentifier('name'): const SilhouetteString('Alice'),
                }),
              }),
            }),
          }),
        );
        expect(result, 'Deep:AliceEnd');
      });

      test('handles array access with trimming', () async {
        final compiled = engine.compile('Item:{{- items[1] -}}Done');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('items'): const SilhouetteList([
              SilhouetteString('first'),
              SilhouetteString('second'),
              SilhouetteString('third'),
            ]),
          }),
        );
        expect(result, 'Item:secondDone');
      });

      test('handles trimming with zero-width content', () async {
        final compiled = engine.compile('Before   {{- "" -}}   After');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'BeforeAfter');
      });

      test('handles whitespace-only template with trimming', () async {
        final compiled = engine.compile('   \n\t  {{- value -}}  \t\n   ');
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('CONTENT'),
          }),
        );
        expect(result, 'CONTENT');
      });

      test(
        'handles property access with trimming',
        () async {
          final compiled = engine.compile(
            'Result:{{- items[0].length -}}chars',
          );
          final result = await compiled.render(
            SilhouetteObject({
              SilhouetteIdentifier('items'): const SilhouetteList([
                SilhouetteString('hello'),
              ]),
            }),
          );
          expect(result, 'Result:5chars');
        },
      );

      test('handles unicode whitespace with trimming', () async {
        // Using various unicode whitespace characters.
        final compiled = engine.compile(
          'Start\u00A0\u2000\u2001{{- value -}}\u2002\u2003End',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('value'): const SilhouetteString('UNICODE'),
          }),
        );
        expect(result, 'StartUNICODEEnd');
      });
    });

    group('Comments', () {
      test('renders template with simple comment', () async {
        final compiled = engine.compile(
          'Hello {{# This is a comment #}} World',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Hello  World');
      });

      test('renders template with comment removed', () async {
        final compiled = engine.compile(
          'Start {{# Ignore this text #}} End',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Start  End');
      });

      test('renders template with multiple comments', () async {
        final compiled = engine.compile(
          'A {{# comment 1 #}} B {{# comment 2 #}} C',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'A  B  C');
      });

      test('renders template with comment at start', () async {
        final compiled = engine.compile('{{# Header #}}Content');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Content');
      });

      test('renders template with comment at end', () async {
        final compiled = engine.compile('Content{{# Footer #}}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Content');
      });

      test('renders template with empty comment', () async {
        final compiled = engine.compile('Hello {{##}} World');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Hello  World');
      });

      test('renders template with comment between variables', () async {
        final compiled = engine.compile(
          '{{ first }}{{# Separator #}}{{ second }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('first'): const SilhouetteString('A'),
            SilhouetteIdentifier('second'): const SilhouetteString('B'),
          }),
        );
        expect(result, 'AB');
      });

      test('renders template with comment containing special chars', () async {
        final compiled = engine.compile(
          'Text {{# Has {{ and }} and {{# inside #}} More',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Text  More');
      });

      test('renders template with multiline comment', () async {
        final compiled = engine.compile(
          'Start {{# This is\na multiline\ncomment #}} End',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Start  End');
      });

      test('renders comment with trim before', () async {
        final compiled = engine.compile('Hello   {{#- comment #}} World');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Hello World');
      });

      test('renders comment with trim after', () async {
        final compiled = engine.compile('Hello {{# comment -#}}   World');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Hello World');
      });

      test('renders comment with trim both sides', () async {
        final compiled = engine.compile('Hello   {{#- comment -#}}   World');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'HelloWorld');
      });

      test('renders multiple comments with whitespace control', () async {
        final compiled = engine.compile(
          'A   {{#- c1 -#}}   B   {{#- c2 -#}}   C',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'ABC');
      });

      test('renders comment with trim around variables', () async {
        final compiled = engine.compile(
          'Hello   {{#- doc -#}}   {{ name }}!',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('World'),
          }),
        );
        expect(result, 'HelloWorld!');
      });

      test('renders comment between trimmed tags', () async {
        final compiled = engine.compile(
          '{{ greeting -}}   {{#- space -#}}   {{- name }}!',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('greeting'): const SilhouetteString('Hello'),
            SilhouetteIdentifier('name'): const SilhouetteString('World'),
          }),
        );
        expect(result, 'HelloWorld!');
      });

      test('renders complex template with mixed comments and tags', () async {
        final compiled = engine.compile(
          '{{# Template header #}}'
          'Name: {{ name }}'
          '{{# Middle comment #}}'
          ', Age: {{ age }}'
          '{{# Footer #}}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Alice'),
            SilhouetteIdentifier('age'): const SilhouetteInt(30),
          }),
        );
        expect(result, 'Name: Alice, Age: 30');
      });

      test('renders comment with trim and newlines', () async {
        final compiled = engine.compile(
          'Line1\n'
          '  {{#- comment -#}}  \n'
          'Line2',
        );
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, 'Line1Line2');
      });

      test('renders only comment', () async {
        final compiled = engine.compile('{{# Only comment #}}');
        final result = await compiled.render(const SilhouetteObject({}));
        expect(result, '');
      });

      test('renders documentation-style comments', () async {
        final compiled = engine.compile(
          '{{#\n'
          '  Template: user_profile.html\n'
          '  Description: Renders user profile information\n'
          '  Variables: name, email, age\n'
          '#}}\n'
          'User: {{ name }}, Email: {{ email }}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('name'): const SilhouetteString('Bob'),
            SilhouetteIdentifier('email'): const SilhouetteString(
              'bob@example.com',
            ),
          }),
        );
        expect(result, '\nUser: Bob, Email: bob@example.com');
      });

      test('renders inline comments for clarity', () async {
        final compiled = engine.compile(
          'Total: {{ price }}{{# base price #}} + {{ tax }}{{# sales tax #}}',
        );
        final result = await compiled.render(
          SilhouetteObject({
            SilhouetteIdentifier('price'): const SilhouetteInt(100),
            SilhouetteIdentifier('tax'): const SilhouetteInt(10),
          }),
        );
        expect(result, 'Total: 100 + 10');
      });
    });
  });
}
