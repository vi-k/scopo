import 'dart:convert';
import 'dart:io';

// Each document maps section/name keys to the context its verbatim blocks need.
// Add another document here to extend coverage; unlisted blocks fail closed.
final _documents = <String, Map<String, _Environment>>{
  'doc/async_data_scope.md': {
    'asyncdatascope/asyncdatascope-database': _widget,
    'the-value-in-each-place/return-await-database-open':
        const _Environment('Future<Database> example() async {', '}'),
    'the-value-in-each-place/wrong-the-database-is-open-and': _arguments,
    'the-value-in-each-place/right-whatever-ends-the-body-e': _arguments,
    'the-value-in-each-place/initdata-context-ctx-async': _arguments,
    'reading-it-from-the-subtree/final-database-asyncdatascope-': _widget,
    'reading-it-from-the-subtree/final-name-asyncdatascope-sele': _widget,
  },
};

const _widget = _Environment('void example(BuildContext context) {', '}');
const _arguments = _Environment(
  'void example(BuildContext context) {\nAsyncDataScope<Database>(',
  'progressBuilder: (context, progress) => Text("\$progress"),\n'
      'errorBuilder: (context, error, stack, progress) => Text("\$error"),\n'
      'builder: (context, database) => DatabaseView(database: database),\n);\n}',
);
// This contract probe is separate from the document's blocks, but uses the
// same environment and diagnostic matching as an intentional negative example.
const _negativeKey = 'contracts/ScopeInitContext.progress(null)';
const _negative = _Environment(
  'void example(ScopeInitContext ctx) {',
  '}',
  expectedErrors: ['argument_type_not_assignable'],
);
const _support = r'''
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';

class Database {
  static Future<Database> open() async => Database();
  Future<void> migrate() async {}
  Future<void> close() async {}
}

class DatabaseView extends StatelessWidget {
  const DatabaseView({super.key, required this.database});
  final Database database;
  @override
  Widget build(BuildContext context) => Text('$database');
}

class Profile {
  String get name => 'Ada';
}
''';

final class _Environment {
  final String before;
  final String after;
  final List<String> expectedErrors;

  const _Environment(this.before, this.after, {this.expectedErrors = const []});

  String wrap(String block) => '$_support\n$before\n$block$after\n';
}

final class _Example {
  final String key;
  final String source;
  final _Environment environment;

  const _Example(this.key, this.source, this.environment);
}

/// Checks all Dart blocks against the local package, without writing to it.
///
/// An optional argument selects the parent of the temporary package. Analysis
/// uses the running Dart SDK with machine output: only errors are contractual,
/// so an illustrative local variable's unused warning is not a failed example.
Future<void> main(List<String> arguments) async {
  Directory? bench;
  try {
    if (arguments.length > 1) {
      throw const FormatException(
        'Usage: check_doc_examples.dart [temp-parent]',
      );
    }
    final root = File.fromUri(Platform.script).parent.parent.absolute;
    final examples = <_Example>[];
    for (final document in _documents.entries) {
      final blocks = _extract(File('${root.path}/${document.key}'));
      final missing =
          document.value.keys.toSet().difference(blocks.keys.toSet());
      final extra = blocks.keys.toSet().difference(document.value.keys.toSet());
      if (missing.isNotEmpty || extra.isNotEmpty) {
        throw FormatException(
          [
            for (final key in missing) '${document.key}: missing key $key',
            for (final key in extra) '${document.key}: unlisted key $key',
          ].join('\n'),
        );
      }
      for (final entry in document.value.entries) {
        examples.add(
          _Example(
            '${document.key}:${entry.key}',
            blocks[entry.key]!,
            entry.value,
          ),
        );
      }
    }
    examples
        .add(const _Example(_negativeKey, 'ctx.progress(null);\n', _negative));

    final parent = arguments.isEmpty
        ? Directory.systemTemp
        : Directory(arguments.single).absolute;
    await parent.create(recursive: true);
    // Resolved, because the analyzer reports resolved paths: on macOS the
    // temporary directory sits behind the `/tmp` or `/var` symlink, and an
    // unresolved bench matches none of its own diagnostics.
    final created = await parent.createTemp('scopo-doc-examples-');
    bench = Directory(await created.resolveSymbolicLinks());
    await File('${bench.path}/pubspec.yaml').writeAsString('''
name: scopo_doc_examples
publish_to: none
environment:
  sdk: ^3.6.0
dependencies:
  flutter:
    sdk: flutter
  scopo:
    path: ${jsonEncode(root.path)}
''');
    final sources = await Directory('${bench.path}/lib').create();
    final byFile = <String, _Example>{};
    for (var i = 0; i < examples.length; i++) {
      final example = examples[i];
      final file = File('${sources.path}/example_$i.dart');
      await file.writeAsString(example.environment.wrap(example.source));
      byFile[file.absolute.path] = example;
    }

    final get = await Process.run(
      _flutterExecutable(),
      ['pub', 'get'],
      workingDirectory: bench.path,
    );
    if (get.exitCode != 0) {
      throw ProcessException(
        'flutter',
        ['pub', 'get'],
        '${get.stdout}\n${get.stderr}',
        get.exitCode,
      );
    }
    final analysis = await Process.run(
      Platform.resolvedExecutable,
      [
        'analyze',
        '--format=machine',
        '--no-fatal-warnings',
        'lib',
      ],
      workingDirectory: bench.path,
    );
    final errors = <String, List<String>>{};
    final details = <String, List<String>>{};
    for (final line in const LineSplitter()
        .convert('${analysis.stdout}\n${analysis.stderr}')) {
      final fields = line.split('|');
      if (fields.length < 8 || fields.first != 'ERROR') continue;
      final path = File(fields[3]).absolute.path;
      if (!byFile.containsKey(path)) {
        throw FormatException('Diagnostic outside manifest: $line');
      }
      errors.putIfAbsent(path, () => []).add(fields[2].toLowerCase());
      details.putIfAbsent(path, () => []).add(line);
    }
    if (analysis.exitCode != 0 && errors.isEmpty) {
      throw ProcessException(
        'dart',
        ['analyze'],
        '${analysis.stdout}\n${analysis.stderr}',
        analysis.exitCode,
      );
    }
    var failed = false;
    for (final entry in byFile.entries) {
      final actual = (errors[entry.key] ?? []).toList()..sort();
      final expected = entry.value.environment.expectedErrors.toList()..sort();
      final matches = jsonEncode(actual) == jsonEncode(expected);
      final expectation = expected.isEmpty ? 'no errors' : expected.join(', ');
      stdout.writeln('${matches ? "PASS" : "FAIL"} ${entry.value.key}: '
          'expected $expectation; got ${actual.isEmpty ? "no errors" : actual.join(", ")}');
      if (!matches) {
        failed = true;
        (details[entry.key] ?? <String>[]).forEach(stderr.writeln);
      }
    }
    if (failed) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    await bench?.delete(recursive: true);
  }
}

String _flutterExecutable() {
  // Dart is <flutter>/bin/cache/dart-sdk/bin/dart under fvm and in CI.
  final bin = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final flutter =
      File('${bin.path}/flutter${Platform.isWindows ? ".bat" : ""}');
  if (flutter.existsSync()) return flutter.path;
  return Platform.isWindows ? 'flutter.bat' : 'flutter';
}

// Like doc_blocks.py: a section slug plus each declaration, or the first
// line's slug for a body fragment. The introduction belongs to the H1 slug.
// Fence contents are sliced from the original string, never trimmed/reflowed.
Map<String, String> _extract(File document) {
  final text = document.readAsStringSync();
  final blocks = <String, String>{};
  final declarations = RegExp(
    '^(?:(?:final|abstract|sealed|base|interface) )*'
    r'(?:class|enum|mixin|extension|typedef)\s+(\w+)'
    r'|^[A-Za-z_][\w<>,?\[\] ]*\s(\w+)\s*\(',
    multiLine: true,
  );
  var section = 'introduction';
  String? fence;
  var isDart = false;
  var start = 0;
  var offset = 0;
  for (final line in const LineSplitter().convert(text)) {
    final end = text.indexOf('\n', offset);
    final next = end == -1 ? text.length : end + 1;
    if (fence != null) {
      if (RegExp('^${RegExp.escape(fence)}\\s*\$').hasMatch(line)) {
        if (isDart) {
          final block = text.substring(start, offset);
          final names = declarations
              .allMatches(block)
              .map((match) => match.group(1) ?? match.group(2)!);
          for (final name
              in names.isEmpty ? [_slug(block.split('\n').first)] : names) {
            final key = '$section/$name';
            if (blocks.containsKey(key)) {
              throw FormatException('${document.path}: duplicate key $key');
            }
            blocks[key] = block;
          }
        }
        fence = null;
      }
    } else {
      final heading = RegExp(r'^#{1,2} (.+)$').firstMatch(line);
      final opening = RegExp(r'^(`{3,}|~{3,})(\S*)\s*$').firstMatch(line);
      if (heading != null) {
        final title = heading.group(1)!;
        section =
            RegExp(r'^(\d+)\.').firstMatch(title)?.group(1) ?? _slug(title);
      } else if (opening != null) {
        fence = opening.group(1);
        isDart = opening.group(2) == 'dart';
        start = next;
      }
    }
    offset = next;
  }
  if (fence != null) {
    throw FormatException('${document.path}: unclosed fence in $section');
  }
  return blocks;
}

String _slug(String text) {
  final slug = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}_]+', unicode: true), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.length > 30 ? slug.substring(0, 30) : slug;
}
