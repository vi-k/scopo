// scopo: a screen that owns a database and a session built on top of it.
// Loading with progress, an error branch, cancellation when the widget
// leaves, teardown in reverse order, and `scopeKey` so that a re-created
// screen waits for the previous database to be closed.
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'common.dart';

final class ScreenDeps extends ScopeAutoDependencies<ScreenDeps, void> {
  late final Db db;
  late final Session session;

  @override
  ScopeDependency buildDependencies(void _) => sequential('', [
        dep('db', (dep) async {
          db = await Db.open();
          dep.dispose = db.close; // registered the moment it is held
        }),
        dep('session', (dep) async {
          session = await Session.open(db);
          dep.dispose = session.close;
        }),
      ]);
}

final class ScreenScope extends Scope<ScreenScope, ScreenDeps, ScreenState> {
  const ScreenScope({super.key}) : super(scopeKey: Db);

  @override
  Future<ScreenDeps> initDependencies(
    BuildContext context,
    ScopeInitContext ctx,
  ) =>
      ScreenDeps().init(null, ctx);

  @override
  ScreenState createState() => ScreenState();

  @override
  Widget buildOnProgress(
    BuildContext context,
    covariant ScopeAutoDependenciesProgress? progress,
  ) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress?.value ?? 0),
            Text(progress?.path ?? 'waiting for the previous owner'),
          ],
        ),
      );

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    covariant ScopeAutoDependenciesProgress? progress,
  ) =>
      Center(child: Text('failed at ${progress?.path}: $error'));

  static ScreenState of(BuildContext context) =>
      Scope.of<ScreenScope, ScreenDeps, ScreenState>(context);
}

final class ScreenState extends ScopeState<ScreenScope, ScreenDeps, ScreenState> {
  @override
  Widget build(BuildContext context) => Center(
        child: Text('session on db closed=${dependencies.db.closed}'),
      );
}

/// Root: the coordinator serves `scopeKey`; a button re-creates the screen.
class ScopoProbeApp extends StatefulWidget {
  const ScopoProbeApp({super.key});

  @override
  State<ScopoProbeApp> createState() => _ScopoProbeAppState();
}

class _ScopoProbeAppState extends State<ScopoProbeApp> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) => AsyncScopeCoordinator(
        child: MaterialApp(
          home: Scaffold(
            body: ScreenScope(key: ValueKey(_generation)),
            floatingActionButton: FloatingActionButton(
              onPressed: () => setState(() => _generation++),
              child: const Icon(Icons.refresh),
            ),
          ),
        ),
      );
}
