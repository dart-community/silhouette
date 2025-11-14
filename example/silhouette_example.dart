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
