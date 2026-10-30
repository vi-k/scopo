import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain.dart';

/// Riverpod, the way its docs put `onDispose` right after creation.
final dbProvider = FutureProvider.autoDispose<Database>((ref) async {
  final db = await Database.open();
  // Riverpod 3 throws UnmountedRefException here if the screen already left,
  // and the database is never closed -- so guard with `ref.mounted`.
  if (!ref.mounted) {
    unawaited(db.close());
    throw StateError('left before the database opened');
  }
  // `onDispose` takes a synchronous callback: the close is started, not awaited.
  ref.onDispose(() => unawaited(db.close()));
  return db;
});

final sessionProvider = FutureProvider.autoDispose<Session>((ref) async {
  final db = await ref.watch(dbProvider.future);
  final session = await Session.restore(db);
  if (!ref.mounted) {
    unawaited(session.close());
    throw StateError('left before the session was restored');
  }
  ref.onDispose(() => unawaited(session.close()));
  return session;
});

class RiverpodAccountScreen extends ConsumerWidget {
  const RiverpodAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(sessionProvider)) {
        AsyncData(:final value) => Text('ready: ${value.user}'),
        AsyncError(:final error) => Text('error: $error'),
        _ => const Text('loading'),
      };
}

/// The same, without the `ref.mounted` guard -- the shape the docs show.
final naiveDbProvider = FutureProvider.autoDispose<Database>((ref) async {
  final db = await Database.open();
  ref.onDispose(() => unawaited(db.close()));
  return db;
});

final naiveSessionProvider = FutureProvider.autoDispose<Session>((ref) async {
  final db = await ref.watch(naiveDbProvider.future);
  final session = await Session.restore(db);
  ref.onDispose(() => unawaited(session.close()));
  return session;
});

class NaiveRiverpodAccountScreen extends ConsumerWidget {
  const NaiveRiverpodAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(naiveSessionProvider)) {
        AsyncData(:final value) => Text('ready: ${value.user}'),
        AsyncError(:final error) => Text('error: $error'),
        _ => const Text('loading'),
      };
}
