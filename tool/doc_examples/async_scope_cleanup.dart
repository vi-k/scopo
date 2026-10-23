import 'manifest.dart';

/// Runs the partial-cleanup recipe with failing assembly and disposers.
const partialCleanup = DocExecution(
  '''
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

final original = Exception('connection assembly failed');
final originalStack = StackTrace.fromString('connection assembly stack');
final sessionFailure = Exception('session close failed');
final sessionStack = StackTrace.fromString('session close stack');
final databaseFailure = Exception('database close failed');
final databaseStack = StackTrace.fromString('database close stack');
final releases = <String>[];
var synchronousFailure = false;
var databaseFails = false;
var assemblyFails = true;
late Connection connection;

class Connection {
  Connection(Database database, Session session) {
    if (assemblyFails) Error.throwWithStackTrace(original, originalStack);
  }
}

class Database {
  static Future<Database> open() async => Database();
  Future<void> close() async {
    releases.add('database');
    if (databaseFails) {
      Error.throwWithStackTrace(databaseFailure, databaseStack);
    }
  }
}

class Session {
  static Future<Session> connect() async => Session();
  Future<void> close() {
    releases.add('session');
    if (synchronousFailure) {
      Error.throwWithStackTrace(sessionFailure, sessionStack);
    }
    return Future<void>.error(sessionFailure, sessionStack);
  }
}

class _Context {
  void progress(String message) {}
}

Future<void> example(_Context ctx) async {
''',
  r'''
}

void main() {
  setUp(() {
    releases.clear();
    synchronousFailure = false;
    databaseFails = false;
    assemblyFails = true;
  });

  for (final scenario in ['async release', 'sync release', 'both releases']) {
    test('partial cleanup preserves all failures: $scenario', () async {
      synchronousFailure = scenario == 'sync release';
      databaseFails = scenario == 'both releases';
      final reports = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      Object? observed;
      StackTrace? observedStack;
      FlutterError.onError = reports.add;
      try {
        await example(_Context());
      } on Object catch (error, stack) {
        observed = error;
        observedStack = stack;
      } finally {
        FlutterError.onError = previous;
      }
      expect(releases, ['session', 'database'],
          reason: 'every acquired resource must be released in reverse order');
      expect(observed, same(original),
          reason: 'cleanup must not replace the assembly error');
      expect(observedStack.toString(), originalStack.toString());
      expect(reports.map((report) => report.exception),
          [sessionFailure, if (databaseFails) databaseFailure],
          reason: 'secondary failures must be reported');
      expect(reports.map((report) => report.stack.toString()),
          [sessionStack.toString(), if (databaseFails) databaseStack.toString()]);
    });
  }

  test('successful assembly hands resources over without releasing them',
      () async {
    assemblyFails = false;
    await example(_Context());
    expect(connection, isA<Connection>());
    expect(releases, isEmpty);
  });
}
''',
);
