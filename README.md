A Dart package with support for a simple template language and engine
that's built to be familiar to Dart developers.

## Installation

To use `package:silhouette` and access its keyword information,
first add it as a dependency in your `pubspec.yaml` file:

```shell
dart pub add silhouette
```

## Usage

The package provides a singular built-in library:

- `package:silhouette/silhouette.dart`

  Primarily provides access to the `TemplateEngine` and `CompiledTemplate` types
  to compile and render Silhouette templates, as well as the
  various types used to soundly represent data within templates.

### File extension

By convention, Silhouette templates use the `.sil` file extension.
For example: `template.sil`, `email.sil`, `layout.sil`.

### Compile and render a template string

```dart
import 'package:silhouette/silhouette.dart';

void main() async {
  final engine = TemplateEngine();

  final template = engine.compile(
    'Hello {{ name }}! You have {{ count }} messages.',
  );

  final result = await template.render(
    {'name': 'Dash', 'count': 3}.toSilhouetteObject,
  );

  print(result);
}
```

## Template syntax

### Variables

```sil
Hello {{ name }}!
```

### Property access

```sil
Hello {{ user.name }}!
```

### List and map indexing

```sil
The first item is {{ items[0] }}.
The item at row {{ row }}, column {{ col }} is {{ matrix[row][col] }}.
```

### Method calls

```sil
WHY ARE YOU SHOUTING {{ name.toUpperCase() }}?

I'm searching for "{{ rawText.trim().toLowerCase() }}".
```

### Literals

```sil
{{ "Hello World" }}
{{ 42 }}
{{ 3.14159 }}
{{ true }}
{{ null }}
```

### Whitespace control

```sil
This text is squished between two colons:    {{- text -}}    :'
```
