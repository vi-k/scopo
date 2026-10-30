// yx_scope + yx_scope_flutter: the same screen. A container declares the two
// async deps and their order in `initializeQueue`; a holder creates and drops
// the scope; the widget state owns the holder. Loading is the placeholder of
// `ScopeBuilder.withPlaceholder`; the error branch and the progress value
// have to be written by hand.
import 'package:flutter/material.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

import 'common.dart';

/// yx_scope wants `init()`/`dispose()` on the object itself, so the
/// static `Db.open()` is wrapped in a handle.
class DbHandle implements AsyncLifecycle {
  late Db db;

  @override
  Future<void> init() async => db = await Db.open();

  @override
  Future<void> dispose() => db.close();
}

class SessionHandle implements AsyncLifecycle {
  final DbHandle dbHandle;
  late Session session;

  SessionHandle(this.dbHandle);

  @override
  Future<void> init() async => session = await Session.open(dbHandle.db);

  @override
  Future<void> dispose() => session.close();
}

abstract class ScreenScope {
  Session get session;
}

class ScreenScopeContainer extends ScopeContainer implements ScreenScope {
  late final dbDep = asyncDep(() => DbHandle());
  late final sessionDep = asyncDep(() => SessionHandle(dbDep.get));

  @override
  List<Set<AsyncDep>> get initializeQueue => [
        {dbDep},
        {sessionDep},
      ];

  @override
  Session get session => sessionDep.get.session;
}

class ScreenScopeHolder extends ScopeHolder<ScreenScopeContainer> {
  @override
  ScreenScopeContainer createContainer() => ScreenScopeContainer();
}

class YxScreen extends StatefulWidget {
  const YxScreen({super.key});

  @override
  State<YxScreen> createState() => _YxScreenState();
}

class _YxScreenState extends State<YxScreen> {
  final _holder = ScreenScopeHolder();
  Object? _error;

  @override
  void initState() {
    super.initState();
    // A failed `init` of a dep disposes the deps already initialized, in
    // reverse, and rethrows here; the holder goes back to `none`. The error
    // branch is this widget's own: nothing in the package draws it.
    _holder.create().catchError((Object e) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  void dispose() {
    // `drop()` awaits the disposers in reverse queue order, but `dispose()`
    // of a State is synchronous: nothing above waits for this future, and a
    // `create()` still running is not cancelled -- `drop()` waits for it to
    // finish first.
    _holder.drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('$_error'));
    return ScopeProvider<ScreenScopeContainer>(
      holder: _holder,
      child: ScopeBuilder<ScreenScopeContainer>.withPlaceholder(
        // No progress value exists; the placeholder covers `initializing`.
        placeholder: const Center(child: CircularProgressIndicator()),
        builder: (context, scope) => Center(
          child: Text('session on db closed=${scope.session.db.closed}'),
        ),
      ),
    );
  }
}

class YxProbeApp extends StatefulWidget {
  const YxProbeApp({super.key});

  @override
  State<YxProbeApp> createState() => _YxProbeAppState();
}

class _YxProbeAppState extends State<YxProbeApp> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          // A re-created screen creates a new holder at once; the previous
          // `drop()` is still closing the database. Serialising the two
          // owners is the application's job.
          body: YxScreen(key: ValueKey(_generation)),
          floatingActionButton: FloatingActionButton(
            onPressed: () => setState(() => _generation++),
            child: const Icon(Icons.refresh),
          ),
        ),
      );
}
