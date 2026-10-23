import 'manifest.dart';

/// The blocks of the `Scope` topic.
const fullScope = DocManifest(
  'doc/full_scope.md',
  support: _support,
  {
    'the-initialization-branch/AppDependencies': _library,
    'the-initialization-branch/initDependencies': DocEnvironment(
      '$_appDependencies\n'
          'abstract base class ExampleState '
          'extends ScopeState<Example, AppDependencies, ExampleState> {}\n'
          'abstract base class Example '
          'extends Scope<Example, AppDependencies, ExampleState> {',
      '}',
    ),
    'the-initialization-branch/final-job-scopeinitjob-ctx-app': DocEnvironment(
      '$_appDependencies\nFuture<void> example() async {',
      '}',
    ),
    'scopeautodependencies/HomeDependencies': _library,
    'scopeautodependencies/initDependencies': DocEnvironment(
      '$_homeDependencies\n$_scope',
      '}',
    ),
    'scopeautodependencies/buildOnProgress': DocEnvironment(
      '$_homeDependencies\n$_scope',
      '}',
    ),
    'scopeautodependencies/wrong-the-migration-throws-not': _dependency,
    'scopeautodependencies/right-registered-before-anythi': _dependency,
    'scopeautodependencies/init': DocEnvironment(
      'class AppDependencies implements ScopeDependencies {\n'
          'AppDependencies({required Storage storage, required Session session});\n'
          '@override\nvoid onUnmount() {}\n'
          '@override\nFuture<void> dispose() async {}',
      '}',
    ),
    'dependency-paths/sequential': DocEnvironment.skip(
      'Dependency tree diagram with ellipses in place of initializer callbacks.',
    ),
    'disposal-unmount-and-close/initDependencies': DocEnvironment(
      '$_appDependencies\n'
          'abstract base class ExampleState '
          'extends ScopeState<Example, AppDependencies, ExampleState> {}\n'
          'abstract base class Example '
          'extends Scope<Example, AppDependencies, ExampleState> {',
      '}',
    ),
    'disposal-unmount-and-close/buildDependencies': DocEnvironment(
      'class Example extends ScopeAutoDependencies<Example, BuildContext> {',
      '}',
    ),
  },
);

const _library = DocEnvironment('', '');
const _dependency = DocEnvironment(
  'class Example extends ScopeAutoDependencies<Example, void> {\n'
      '@override\nScopeDependency buildDependencies(_) => sequential("", [',
  ']);\n}',
);
const _scope = '''
abstract base class Example
    extends Scope<Example, HomeDependencies, ExampleState> {
''';
const _homeDependencies = '''
final class HomeDependencies
    extends ScopeAutoDependencies<HomeDependencies, void> {
  @override
  ScopeDependency buildDependencies(_) => sequential('', []);
}
abstract base class ExampleState
    extends ScopeState<Example, HomeDependencies, ExampleState> {}
''';
const _appDependencies = '''
class AppDependencies implements ScopeDependencies {
  static Future<AppDependencies> init(ScopeInitContext ctx) async =>
      AppDependencies();
  @override
  void onUnmount() {}
  @override
  Future<void> dispose() async {}
}
''';
const _support = '''
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

class SharedPreferences {
  static Future<SharedPreferences> getInstance() async => SharedPreferences();
}

class ApiClient {
  Future<void> init() async {}
  Future<void> close() async {}
}

class Settings {
  static Future<Settings> load() async => Settings();
  Future<void> save() async {}
}

class Session {
  static Future<Session> restore(Object storage) async => Session();
  Future<void> close() async {}
}

class Storage {
  static Future<Storage> open() async => Storage();
  Future<void> close() async {}
}

class Database {
  static Future<Database> open() async => Database();
  Future<void> migrate() async {}
  Future<void> close() async {}
}

class Connection {
  static Future<Connection> open() async => Connection();
  Future<void> close() async {}
}

Future<T> somethingThatFails<T>() async =>
    throw StateError('Initialization failed');
''';
