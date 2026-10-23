import 'package:flutter_test/flutter_test.dart';

import 'ide/scopo_deps.dart' as snippet;

void main() {
  test('scopo-deps closes the database after session disposal fails', () async {
    final closed = <String>[];
    final failure = StateError('session close failed');
    final dependencies = snippet.AppDependencies(
      session: snippet.Session(
        onClose: () async {
          closed.add('session');
          throw failure;
        },
      ),
      database: snippet.Database(
        onClose: () async {
          closed.add('database');
        },
      ),
    );

    await expectLater(dependencies.dispose(), throwsA(same(failure)));
    expect(closed, ['session', 'database']);
  });

  test('scopo-deps awaits each close once in reverse acquisition order',
      () async {
    final closed = <String>[];
    final dependencies = snippet.AppDependencies(
      session: snippet.Session(
        onClose: () async {
          closed.add('session start');
          await Future<void>.delayed(Duration.zero);
          closed.add('session end');
        },
      ),
      database: snippet.Database(
        onClose: () async {
          closed.add('database start');
          await Future<void>.delayed(Duration.zero);
          closed.add('database end');
        },
      ),
    );

    await dependencies.dispose();
    expect(
      closed,
      ['session start', 'session end', 'database start', 'database end'],
    );
  });

  test('scopo-deps propagates a database disposal failure', () async {
    final failure = StateError('database close failed');
    final dependencies = snippet.AppDependencies(
      session: snippet.Session(),
      database: snippet.Database(onClose: () async => throw failure),
    );

    await expectLater(dependencies.dispose(), throwsA(same(failure)));
  });

  test('scopo-deps closes the database when both closes fail', () async {
    final closed = <String>[];
    final database = StateError('database close failed');
    final dependencies = snippet.AppDependencies(
      session: snippet.Session(
        onClose: () async {
          closed.add('session');
          throw StateError('session close failed');
        },
      ),
      database: snippet.Database(
        onClose: () async {
          closed.add('database');
          throw database;
        },
      ),
    );

    await expectLater(dependencies.dispose(), throwsA(same(database)));
    expect(closed, ['session', 'database']);
  });
}
