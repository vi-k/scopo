import 'manifest.dart';

/// The blocks of the `AsyncDataScope` topic.
const asyncDataScope = DocManifest(
  'doc/async_data_scope.md',
  support: _support,
  {
    'asyncdatascope/asyncdatascope-database': _widget,
    'the-value-in-each-place/return-await-database-open':
        DocEnvironment('Future<Database> example() async {', '}'),
    'the-value-in-each-place/wrong-the-database-is-open-and': _arguments,
    'the-value-in-each-place/right-whatever-ends-the-body-e': _arguments,
    'the-value-in-each-place/initdata-context-ctx-async': _arguments,
    'reading-it-from-the-subtree/final-database-asyncdatascope-': _widget,
    'reading-it-from-the-subtree/final-name-asyncdatascope-sele': _widget,
  },
);

const _widget = DocEnvironment('void example(BuildContext context) {', '}');
const _arguments = DocEnvironment(
  'void example(BuildContext context) {\nAsyncDataScope<Database>(',
  'progressBuilder: (context, progress) => Text("\$progress"),\n'
      'errorBuilder: (context, error, stack, progress) => Text("\$error"),\n'
      'builder: (context, database) => DatabaseView(database: database),\n);\n}',
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
