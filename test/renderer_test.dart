import 'dart:async';

import 'package:silhouette/silhouette.dart';
import 'package:test/test.dart';

void main() {
  group('Renderer scopes', () {
    test('context values shadow globals, including null and false', () async {
      final engine = TemplateEngine(
        globals: {
          'fallback': 'global',
          'nullable': 'global',
          'flag': true,
          'count': 1,
          'text': 'global',
        }.toSilhouetteObject,
      );
      final compiled = engine.compile(
        '{{ fallback }}:{{ nullable }}:{{ flag }}:{{ count }}:{{ text }}',
      );

      expect(
        await compiled.render(
          {
            'nullable': null,
            'flag': false,
            'count': 0,
            'text': '',
          }.toSilhouetteObject,
        ),
        'global:null:false:0:',
      );
      expect(await compiled.render(), 'global:global:true:1:global');
    });

    test(
      'nested loops restore bindings when reusing a variable name',
      () async {
        final compiled = TemplateEngine().compile(
          '{{ for item in items }}'
          '[{{ for item in item }}{{ item }}{{ /for }}:{{ item.length }}]'
          '{{ /for }}{{ item }}',
        );

        expect(
          await compiled.render(
            {
              'item': 'outer',
              'items': [
                [1, 2],
                <int>[],
                [3],
              ],
            }.toSilhouetteObject,
          ),
          '[12:2][:0][3:1]outer',
        );
      },
    );

    test('a null loop value shadows the context and globals', () async {
      final compiled = TemplateEngine(
        globals: {'item': 'global'}.toSilhouetteObject,
      ).compile('{{ for item in items }}{{ item }}{{ /for }}:{{ item }}');

      expect(
        await compiled.render(
          {
            'item': 'context',
            'items': [null],
          }.toSilhouetteObject,
        ),
        'null:context',
      );
    });

    test('loop bindings do not leak into the surrounding scope', () async {
      final compiled = TemplateEngine().compile(
        '{{ for item in items }}{{ item }}{{ /for }}{{ item }}',
      );

      await expectLater(
        compiled.render(
          {
            'items': [1],
          }.toSilhouetteObject,
        ),
        throwsA(
          isA<SilhouetteException>().having(
            (error) => error.message,
            'message',
            'Undefined variable: item',
          ),
        ),
      );
    });
  });

  group('Asynchronous rendering', () {
    test('awaits properties and arguments before invoking a method', () async {
      final property = Completer<SilhouetteObject>();
      final calls = <String>[];
      SilhouetteFunction recorded(String name, int result) =>
          SilhouetteFunction((_) async {
            calls.add(name);
            await Future<void>.delayed(Duration.zero);
            calls.add('$name complete');
            return SilhouetteInt(result);
          });
      final compiled = TemplateEngine().compile(
        '{{ user.name.substring(start(), end: end()) }}',
      );
      final result = compiled.render(
        {
          'user': _DeferredObject(property.future),
          'start': recorded('start', 1),
          'end': recorded('end', 3),
        }.toSilhouetteObject,
      );

      property.complete({'name': 'Dash'}.toSilhouetteObject);

      expect(await result, 'as');
      expect(calls, ['start', 'start complete', 'end', 'end complete']);
    });

    test('awaits each loop body before advancing its binding', () async {
      final calls = <String>[];
      final compiled = TemplateEngine().compile(
        '{{ for item in items }}{{ echo(item) }}:{{ item }};{{ /for }}',
      );

      final result = await compiled.render(
        {
          'items': [1, 2],
          'echo': SilhouetteFunction((args) async {
            final value = args.positional.single;
            calls.add('start $value');
            await Future<void>.delayed(Duration.zero);
            calls.add('end $value');
            return value;
          }),
        }.toSilhouetteObject,
      );

      expect(result, '1:1;2:2;');
      expect(calls, ['start 1', 'end 1', 'start 2', 'end 2']);
    });

    test('concurrent renders keep independent scopes and output', () async {
      final compiled = TemplateEngine().compile(
        '{{ for item in items }}{{ echo(item) }}:{{ item }};{{ /for }}'
        '{{ item }}',
      );
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final releaseSecond = Completer<void>();

      SilhouetteObject context(
        String item,
        Completer<void> started,
        Future<void> released,
      ) => {
        'item': 'outer $item',
        'items': [item],
        'echo': SilhouetteFunction((args) async {
          started.complete();
          await released;
          return args.positional.single;
        }),
      }.toSilhouetteObject;

      final first = compiled.render(
        context('first', firstStarted, releaseFirst.future),
      );
      final second = compiled.render(
        context('second', secondStarted, releaseSecond.future),
      );
      await Future.wait([firstStarted.future, secondStarted.future]);

      releaseSecond.complete();
      expect(await second, 'second:second;outer second');
      releaseFirst.complete();
      expect(await first, 'first:first;outer first');
    });

    test('propagates async loop errors and allows rendering again', () async {
      final failure = StateError('Failed to render item');
      var shouldFail = true;
      final compiled = TemplateEngine().compile(
        '{{ for item in items }}{{ echo(item) }}{{ /for }}:{{ item }}',
      );
      final context = {
        'item': 'outer',
        'items': [1, 2],
        'echo': SilhouetteFunction((args) async {
          await Future<void>.delayed(Duration.zero);
          if (shouldFail) throw failure;
          return args.positional.single;
        }),
      }.toSilhouetteObject;

      await expectLater(compiled.render(context), throwsA(same(failure)));

      shouldFail = false;
      expect(await compiled.render(context), '12:outer');
    });
  });
}

final class _DeferredObject extends SilhouetteValue {
  final Future<SilhouetteObject> _object;

  const _DeferredObject(this._object);

  @override
  Future<SilhouetteValue> retrieve(SilhouetteIdentifier propertyName) async =>
      (await _object).retrieve(propertyName);

  @override
  String toString() => 'deferred object';
}
