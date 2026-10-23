import 'async_scope_cleanup.dart';
import 'manifest.dart';

/// The blocks of the `AsyncScope` topic.
const asyncScope = DocManifest(
  'doc/async_scope.md',
  support: _support,
  {
    'asyncscope/asyncscope': _widget,
    'progress/asyncscope': _widget,
    'progress/initscope-context-ctx-async': DocEnvironment(
      'void example() {\nAsyncScope(',
      'disposeScope: api.close,\n'
          'errorBuilder: (context, error, stack, progress) => Text("\$error"),\n'
          'builder: (context) => const HomeScreen(),\n);\n}',
    ),
    'reading-the-state-from-the-sub/final-scope-asyncscope-of-cont':
        DocEnvironment.skip('Schematic conditional body contains an ellipsis.'),
    'disposal-in-order/wrong-the-connection-is-open-a': _arguments,
    'disposal-in-order/right-what-a-step-took-is-give': _arguments,
    'disposal-in-order/final-acquired-future-void-fun': DocEnvironment(
      'Future<void> example(ScopeInitContext ctx) async {',
      '}',
      execution: partialCleanup,
    ),
    'disposal-in-order/final-opened-await-ctx-abandon': _initializer,
    'disposal-in-order/await-ctx-abandonable-cache-wa': _initializer,
    'disposal-in-order/await-ctx-join-database-migrat': _initializer,
    'disposal-in-order/ctx-ondispose-temporary-close-': _initializer,
    'close/await-asyncscope-of-context-li': _asyncBody,
    'close/asyncscope': _widget,
    'parents-and-children/waitForChildren': DocEnvironment.skip(
      'Signature sketch uses ellipses for timeout and onTimeout arguments.',
    ),
    'parents-and-children/await-asyncscopecoordinator-wa': _asyncBody,
    'scopekey-and-the-coordinator/asyncscopecoordinator-child-ma':
        DocEnvironment('Widget example() =>', ';'),
    'scopekey-and-the-coordinator/await-asyncscopecoordinator-wa': _asyncBody,
  },
);

const _widget = DocEnvironment('void example() {', '}');
const _asyncBody = DocEnvironment(
  'Future<void> example(BuildContext context) async {',
  '}',
);
const _initializer = DocEnvironment(
  'Future<void> example(ScopeInitContext ctx) async {',
  '}',
);
const _arguments = DocEnvironment(
  'void example() {\nAsyncScope(',
  'progressBuilder: (context, progress) => Text("\$progress"),\n'
      'errorBuilder: (context, error, stack, progress) => Text("\$error"),\n'
      'builder: (context) => const HomeScreen(),\n);\n}',
);
const _support = '''
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

late Connection connection;
final api = ApiClient();
final cache = Cache();
final database = Database();
final temporary = Database();
final session = Session();

class Connection {
  Connection(Object source, Session session);
  Future<void> open() async {}
  Future<void> authenticate() async {}
  Future<void> close() async {}
}

class Api {
  static Future<Connection> connect() async => Connection(Database(), Session());
}

class ApiClient {
  Future<void> connect() async {}
  Future<void> loadProfile() async {}
  Future<void> warmUpCache() async {}
  Future<void> close() async {}
}

class Cache {
  Future<void> warmUp() async {}
}

class Database {
  static Future<Database> open() async => Database();
  Future<void> migrate() async {}
  Future<void> close() async {}
}

class Session {
  static Future<Session> connect() async => Session();
  Future<void> close() async {}
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
