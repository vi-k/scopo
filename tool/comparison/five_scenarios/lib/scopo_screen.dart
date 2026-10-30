import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';

import 'domain.dart';

typedef Account = ({Database db, Session session});

/// scopo: one widget owns both resources for as long as it is on screen.
class ScopoAccountScreen extends StatelessWidget {
  const ScopoAccountScreen({super.key, this.scopeKey});

  /// With a key, a re-created screen waits for the previous owner to let go.
  final Object? scopeKey;

  @override
  Widget build(BuildContext context) => AsyncDataScope<Account>(
        scopeKey: scopeKey,
        initData: (context, ctx) async {
          ctx.progress('opening the database');
          // Leaving ends the wait; a database that arrives later is closed.
          // `discard` also fires if a later step fails.
          final db = await ctx.abandonable(
            Database.open,
            discard: (db) => db.close(),
          );

          ctx.progress('restoring the session');
          final session = await ctx.abandonable(
            () => Session.restore(db),
            discard: (session) => session.close(),
          );

          return (db: db, session: session);
        },
        // Awaited; the order is ours.
        disposeData: (account) async {
          await account.session.close();
          await account.db.close();
        },
        progressBuilder: (context, progress) => Text('loading: $progress'),
        errorBuilder: (context, error, stackTrace, progress) =>
            Text('error: $error'),
        builder: (context, account) => Text('ready: ${account.session.user}'),
      );
}
