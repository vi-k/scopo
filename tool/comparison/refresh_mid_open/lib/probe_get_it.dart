// get_it + watch_it: the same screen. `pushScope` ties a get_it scope to the
// widget; `registerSingletonAsync` with `dependsOn` orders the start;
// `allReady` drives loading and error. The teardown is reverse registration
// order, started by `popScope` when the widget is disposed.
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import 'common.dart';

class GetItScreen extends WatchingWidget {
  const GetItScreen({super.key});

  @override
  Widget build(BuildContext context) {
    pushScope(
      init: (getIt) {
        getIt.registerSingletonAsync<Db>(
          Db.open,
          dispose: (db) => db.close(),
        );
        getIt.registerSingletonAsync<Session>(
          () => Session.open(getIt<Db>()),
          dependsOn: [Db],
          dispose: (session) => session.close(),
        );
      },
      // The pop runs from the widget's dispose; nothing awaits the two
      // disposers, and a factory still in flight is not cancelled.
    );

    final ready = allReady(
      onError: (context, error) => debugPrint('init failed: $error'),
    );
    if (!ready) {
      // No per-step progress: `allReady` is a bool, `isReady<T>()` another.
      return const Center(child: CircularProgressIndicator());
    }
    final session = di<Session>();
    return Center(child: Text('session on db closed=${session.db.closed}'));
  }
}

class GetItProbeApp extends StatefulWidget {
  const GetItProbeApp({super.key});

  @override
  State<GetItProbeApp> createState() => _GetItProbeAppState();
}

class _GetItProbeAppState extends State<GetItProbeApp> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          // A re-created widget pushes a new scope at once; the previous
          // `popScope` may still be awaiting `db.close()`. Two owners of the
          // same resource overlap, and `Db` is now registered twice on the
          // stack until the pop finishes.
          body: GetItScreen(key: ValueKey(_generation)),
          floatingActionButton: FloatingActionButton(
            onPressed: () => setState(() => _generation++),
            child: const Icon(Icons.refresh),
          ),
        ),
      );
}
