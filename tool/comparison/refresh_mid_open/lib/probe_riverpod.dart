// Riverpod 3: the same screen. Two autoDispose FutureProviders, the session
// one awaiting the database one. Loading and error come from AsyncValue.
// What is missing is written next to where it would go.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common.dart';

// Providers are app-wide singletons by default. To give every screen
// instance its own database, both providers are "scoped": they declare
// `dependencies` and are listed in the `overrides` of a nested ProviderScope.
// Without that the nested scope changes nothing (checked by the probe test).
final dbProvider = FutureProvider.autoDispose<Db>(
  (ref) async {
    final db = await Db.open();
    // No cancellation reaches here: if the screen left during `open`, the
    // database is opened for nobody and, since `onDispose` is registered
    // only now, never closed. `ref.mounted` only tells us afterwards.
    ref.onDispose(() {
      db.close(); // `onDispose` takes `void Function()`: the future is dropped.
    });
    return db;
  },
  dependencies: const [],
);

final sessionProvider = FutureProvider.autoDispose<Session>(
  (ref) async {
    final db = await ref.watch(dbProvider.future);
    final session = await Session.open(db);
    ref.onDispose(() {
      session.close(); // not awaited either; nobody waits for it before `db`
    });
    return session;
  },
  dependencies: [dbProvider],
);

class RiverpodScreen extends ConsumerWidget {
  const RiverpodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return switch (session) {
      // There is no progress value: AsyncLoading carries no step.
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => Center(child: Text('$error')),
      AsyncData(:final value) =>
        Center(child: Text('session on db closed=${value.db.closed}')),
    };
  }
}

class RiverpodProbeApp extends StatefulWidget {
  const RiverpodProbeApp({super.key});

  @override
  State<RiverpodProbeApp> createState() => _RiverpodProbeAppState();
}

class _RiverpodProbeAppState extends State<RiverpodProbeApp> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            // A new scoped ProviderScope per generation gives a fresh
            // database; the old one is disposed when its scope leaves the
            // tree, `close()` running while the new `open()` has already
            // started. Nothing serialises the two owners.
            body: ProviderScope(
              key: ValueKey(_generation),
              overrides: [dbProvider, sessionProvider],
              child: const RiverpodScreen(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => setState(() => _generation++),
              child: const Icon(Icons.refresh),
            ),
          ),
        ),
      );
}
