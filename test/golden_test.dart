import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:silhouette/silhouette.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Golden tests', () {
    final inputDir = Directory('test/golden/inputs');
    final outputDir = Directory('test/golden/outputs');

    // Ensure output directory exists.
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    // Find all input files.
    final inputFiles =
        inputDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sil'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final inputFile in inputFiles) {
      final testName = path.basenameWithoutExtension(inputFile.path);
      final outputFile = File(path.join(outputDir.path, '$testName.txt'));

      test(testName, () async {
        final engine = TemplateEngine();

        final (context, template) = _parseInputFile(inputFile);

        final compiledTemplate = engine.compile(template);
        final result = await compiledTemplate.render(context);

        final shouldUpdate = Platform.environment['UPDATE_GOLDENS'] == 'true';

        if (shouldUpdate || !outputFile.existsSync()) {
          // Generate or update golden file.
          outputFile.writeAsStringSync(result);
          if (shouldUpdate) {
            print('Updated golden file: ${outputFile.path}');
          } else {
            print('Generated golden file: ${outputFile.path}');
          }
        } else {
          // Compare with existing golden file.
          final expected = outputFile.readAsStringSync();
          expect(result, expected, reason: 'Golden test failed for $testName');
        }
      });
    }
  });
}

/// Parses an input file containing YAML frontmatter and template content.
///
/// Returns a tuple of (context, template) where context is the parsed
/// YAML data converted to SilhouetteObject and template is the content
/// after the frontmatter.
(SilhouetteObject, String) _parseInputFile(File file) {
  final content = file.readAsStringSync();

  // Check for YAML frontmatter.
  if (!content.startsWith('---\n')) {
    throw ArgumentError('Input file must start with YAML frontmatter');
  }

  // Find the end of frontmatter.
  final endIndex = content.indexOf('\n---\n', 4);
  if (endIndex == -1) {
    throw ArgumentError('Could not find end of YAML frontmatter');
  }

  // Extract frontmatter and template.
  final frontmatter = content.substring(4, endIndex);
  final template = content.substring(endIndex + 5).trim();

  // Parse YAML.
  final yamlData = loadYaml(frontmatter);
  final context = _convertToSilhouetteObject(yamlData);

  return (context, template);
}

/// Converts YAML data to SilhouetteObject format.
SilhouetteObject _convertToSilhouetteObject(dynamic yamlData) {
  if (yamlData is! Map) {
    throw ArgumentError('YAML frontmatter must be a map!');
  }

  final data = <SilhouetteIdentifier, SilhouetteValue>{};

  for (final entry in yamlData.entries) {
    final key = SilhouetteIdentifier(entry.key.toString());
    final value = _convertValue(entry.value);
    data[key] = value;
  }

  return SilhouetteObject(data);
}

/// Converts a YAML value to a SilhouetteValue.
SilhouetteValue _convertValue(Object? value) {
  if (value == null) {
    return SilhouetteNull();
  }

  if (value is String) {
    return SilhouetteString(value);
  }

  if (value is int) {
    return SilhouetteInt(value);
  }

  if (value is double) {
    return SilhouetteDouble(value);
  }

  if (value is bool) {
    return SilhouetteBool(value);
  }

  if (value is List) {
    final convertedList = value.map(_convertValue).toList();
    return SilhouetteList(convertedList);
  }

  if (value is Map) {
    final convertedMap = <SilhouetteIdentifier, SilhouetteValue>{};
    for (final entry in value.entries) {
      final key = SilhouetteIdentifier(entry.key.toString());
      final val = _convertValue(entry.value);
      convertedMap[key] = val;
    }
    return SilhouetteObject(convertedMap);
  }

  // Fallback to string representation.
  return SilhouetteString(value.toString());
}
