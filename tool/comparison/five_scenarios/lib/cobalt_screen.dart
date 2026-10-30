import 'package:cobalt/cobalt.dart';
import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/widgets.dart';

import 'domain.dart';

class DatabaseFactory implements CobaltAsyncFactory<Database> {
  const DatabaseFactory();

  @override
  Future<Database> create(CobaltResolver resolver) => Database.open();
}

class SessionFactory implements CobaltAsyncFactory<Session> {
  const SessionFactory();

  @override
  Future<Session> create(CobaltResolver resolver) =>
      Session.restore(resolver.get<Database>());
}

/// cobalt_flutter: the widget owns a child scope of whatever scope is above.
class CobaltAccountScreen extends CobaltScopedWidget {
  const CobaltAccountScreen({super.key});

  @override
  void registerScope(CobaltScope scope) => scope
    ..registerAsyncSingleton<Database>(
      const DatabaseFactory(),
      dispose: (db) => db.close(),
    )
    ..registerAsyncSingleton<Session>(
      const SessionFactory(),
      dependsOn: {const CobaltKey(Database)},
      dispose: (session) => session.close(),
    );

  @override
  Widget? get loading => const Text('loading');

  @override
  Widget Function(BuildContext context, Object error)? get errorBuilder =>
      (context, error) => Text('error: $error');

  @override
  Widget buildScoped(BuildContext context) =>
      Text('ready: ${context.cobalt<Session>().user}');
}
