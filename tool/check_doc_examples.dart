import 'dart:convert';
import 'dart:io';

import 'doc_examples/async_controller_scope.dart';
import 'doc_examples/async_data_scope.dart';
import 'doc_examples/async_scope.dart';
import 'doc_examples/base.dart';
import 'doc_examples/contracts.dart';
import 'doc_examples/debug.dart';
import 'doc_examples/full_scope.dart';
import 'doc_examples/lite_scope.dart';
import 'doc_examples/manifest.dart';
import 'doc_examples/readme.dart';
import 'doc_examples/scope_model.dart';
import 'doc_examples/scope_notifier.dart';
import 'doc_examples/scope_widget.dart';
import 'doc_examples/utils.dart';

// One manifest per document, in its own file under doc_examples/. Add another
// document here to extend coverage; unlisted blocks fail closed.
const _documents = <DocManifest>[
  readme,
  asyncControllerScope,
  asyncDataScope,
  asyncScope,
  baseTopic,
  debugTopic,
  fullScope,
  liteScope,
  scopeModel,
  scopeNotifier,
  scopeWidget,
  utilsTopic,
];

// Documents that show a whole source file, which its own package analyzes:
// the document's only Dart block must stay that file, byte for byte.
const _copies = <String, String>{
  'example/README.md': 'example/minimal/lib/main.dart',
};

final class _Example {
  final String key;
  final String source;
  final String support;
  final DocEnvironment environment;

  const _Example(this.key, this.source, this.support, this.environment);
}

final class _Block {
  final String section;
  final int line;
  final String source;
  final List<String> keys;

  const _Block(this.section, this.line, this.source, this.keys);
}

/// Checks all Dart blocks against the local package, without writing to it.
///
/// An optional argument selects the parent of the temporary package. Analysis
/// uses the running Dart SDK with machine output: only errors are contractual,
/// so an illustrative local variable's unused warning is not a failed example.
/// The one warning counted with them is an `@override` that overrides nothing:
/// blocks are often wrapped in abstract classes, where a method renamed in the
/// package leaves the document's override compiling.
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
    final problems = <String>[];
    for (final document in _documents) {
      final blocks = _extract(File('${root.path}/${document.path}'));
      final owners = <String, List<_Block>>{};
      for (final block in blocks) {
        for (final key in block.keys) {
          owners.putIfAbsent(key, () => []).add(block);
        }
      }
      final listed = <_Block, String>{};
      for (final entry in document.blocks.entries) {
        final hits = owners[entry.key] ?? const [];
        final lines = hits.map((b) => b.line).join(', ');
        if (hits.isEmpty) {
          problems.add('${document.path}: missing key ${entry.key}');
        } else if (hits.length > 1 && !entry.value.shared) {
          problems.add('${document.path}: key ${entry.key} is declared by '
              'the blocks at lines $lines');
        } else if (hits.length == 1 && entry.value.shared) {
          problems.add('${document.path}: shared key ${entry.key} is '
              'declared by the block at line $lines only');
        } else {
          for (final block in hits) {
            if (listed[block] case final other?) {
              problems.add('${document.path}: the block at line '
                  '${block.line} is listed twice, as $other '
                  'and as ${entry.key}');
              continue;
            }
            listed[block] = entry.key;
            examples.add(
              _Example(
                '${document.path}:${entry.key}'
                '${hits.length > 1 ? '@${block.line}' : ''}',
                block.source,
                document.support,
                entry.value,
              ),
            );
          }
        }
      }
      for (final block in blocks) {
        if (listed.containsKey(block)) continue;
        final unique = [
          for (final key in block.keys)
            if (owners[key]!.length == 1) key,
        ];
        problems.add('${document.path}: the block at line ${block.line} '
            'is unlisted; ${unique.isEmpty ? 'it has no unique key, '
                'declared: ${block.keys.join(', ')}' : 'its keys: '
                '${unique.join(', ')}'}');
      }
    }
    for (final MapEntry(key: path, value: source) in _copies.entries) {
      final blocks = _extract(File('${root.path}/$path'));
      final file = File('${root.path}/$source').readAsStringSync();
      if (blocks.length != 1) {
        problems.add('$path: ${blocks.length} Dart blocks, expected the one '
            'copy of $source');
      } else if (blocks.single.source != file) {
        problems.add('$path: the block at line ${blocks.single.line} is no '
            'longer $source');
      } else {
        stdout.writeln('PASS $path: the copy of $source');
      }
    }
    if (problems.isNotEmpty) throw FormatException(problems.join('\n'));
    for (final probe in contracts) {
      examples.add(
        _Example(probe.key, probe.source, contractSupport, probe.environment),
      );
    }

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
  flutter_test:
    sdk: flutter
  scopo:
    path: ${jsonEncode(root.path)}
''');
    final sources = await Directory('${bench.path}/lib').create();
    final byFile = <String, _Example>{};
    for (var i = 0; i < examples.length; i++) {
      final example = examples[i];
      if (example.environment.skipReason case final reason?) {
        stdout.writeln('SKIP ${example.key}: $reason');
        continue;
      }
      final file = File('${sources.path}/example_$i.dart');
      await file.writeAsString(
        example.environment.wrap(example.support, example.source),
      );
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
      if (fields.length < 8) continue;
      if (fields.first != 'ERROR' &&
          fields[2] != 'OVERRIDE_ON_NON_OVERRIDING_MEMBER') {
        continue;
      }
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
List<_Block> _extract(File document) {
  final text = document.readAsStringSync();
  final blocks = <_Block>[];
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
  var startLine = 0;
  var offset = 0;
  var lineNumber = 0;
  for (final line in const LineSplitter().convert(text)) {
    lineNumber++;
    final end = text.indexOf('\n', offset);
    final next = end == -1 ? text.length : end + 1;
    if (fence != null) {
      if (RegExp('^${RegExp.escape(fence)}\\s*\$').hasMatch(line)) {
        if (isDart) {
          final block = text.substring(start, offset);
          final names = declarations
              .allMatches(block)
              .map((match) => match.group(1) ?? match.group(2)!)
              .toSet();
          blocks.add(
            _Block(section, startLine, block, [
              for (final name
                  in names.isEmpty ? [_slug(block.split('\n').first)] : names)
                '$section/$name',
            ]),
          );
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
        startLine = lineNumber + 1;
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
