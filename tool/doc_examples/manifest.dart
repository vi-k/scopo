/// The context a document's verbatim Dart blocks need to compile.
///
/// [blocks] maps a block's key to its environment. A key is the section slug
/// plus a name the block declares, or the slug of its first line when it
/// declares nothing. A name declared twice in one section is no key at all,
/// unless its environment is [DocEnvironment.shared] and then it covers every
/// block declaring it. Every block of the document is listed exactly once, by
/// any of its keys.
final class DocManifest {
  /// The document, relative to the package root.
  final String path;

  /// Imports and declarations every block of the document may lean on.
  final String support;

  /// The environment of each block, by key.
  final Map<String, DocEnvironment> blocks;

  const DocManifest(this.path, this.blocks, {required this.support});
}

/// What surrounds one block, and which errors the analyzer owes it.
final class DocEnvironment {
  /// Placed before the block.
  final String before;

  /// Placed after the block.
  final String after;

  /// The diagnostic codes a negative example must produce, and nothing else.
  final List<String> expectedErrors;

  /// Why the block is not compiled at all, or `null` when it is.
  final String? skipReason;

  /// Whether the key names several blocks of a section, each compiled in this
  /// environment: two overrides of the same method shown one after another.
  /// A shared key declared by one block only is refused, as is an unshared
  /// key declared by several.
  final bool shared;

  /// An optional executable check using the same verbatim block.
  final DocExecution? execution;

  const DocEnvironment(
    this.before,
    this.after, {
    this.expectedErrors = const [],
    this.shared = false,
    this.execution,
  }) : skipReason = null;

  /// A block that is not Dart a reader could compile, such as a signature
  /// listing. The reason is printed with every run.
  const DocEnvironment.skip(String this.skipReason)
      : before = '',
        after = '',
        expectedErrors = const [],
        shared = false,
        execution = null;

  /// The source of a whole library around [block].
  String wrap(String support, String block) =>
      '$support\n$before\n$block$after\n';
}

/// Fakes and a Flutter test driver surrounding a document's verbatim block.
final class DocExecution {
  /// Imports, fakes and the opening of the function under test.
  final String before;

  /// The end of the function and its test driver.
  final String after;

  const DocExecution(this.before, this.after);

  /// The source of an executable test around [block].
  String wrap(String block) => '$before\n$block$after\n';
}

/// A contract held at compile time, outside any document.
final class ContractProbe {
  /// The name printed with the result.
  final String key;

  /// The code under test.
  final String source;

  /// What surrounds it, and the errors it must produce.
  final DocEnvironment environment;

  const ContractProbe(this.key, this.source, this.environment);
}
