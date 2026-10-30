import 'package:flutter/widgets.dart';
import 'package:watch_it/watch_it.dart';

import 'domain.dart';

/// get_it + watch_it: a get_it scope pushed for as long as the widget lives.
class WatchItAccountScreen extends WatchingWidget {
  const WatchItAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    pushScope(
      init: (getIt) => getIt
        ..registerSingletonAsync<Database>(
          Database.open,
          dispose: (db) => db.close(),
        )
        ..registerSingletonAsync<Session>(
          () => Session.restore(getIt<Database>()),
          dependsOn: [Database],
          dispose: (session) => session.close(),
        ),
    );

    Object? failure;
    final ready = allReady(
      onError: (context, error) => failure = error,
    );
    if (failure != null) return Text('error: $failure');
    if (!ready) return const Text('loading');
    return Text('ready: ${di<Session>().user}');
  }
}
