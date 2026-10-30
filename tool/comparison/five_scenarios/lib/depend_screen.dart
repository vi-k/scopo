import 'package:depend/depend.dart';
import 'package:flutter/widgets.dart';

import 'domain.dart';

class AccountContainer extends DependencyContainer {
  AccountContainer(this.db, this.session);

  final Database db;
  final Session session;

  @override
  void dispose() {
    // `dispose` is synchronous here: the closes are started, not awaited.
    session.close();
    db.close();
  }
}

class AccountFactory extends DependencyFactory<AccountContainer> {
  @override
  Future<AccountContainer> create() async {
    final db = await Database.open();
    final session = await Session.restore(db);
    return AccountContainer(db, session);
  }
}

final _factory = AccountFactory();

class DependAccountScreen extends StatelessWidget {
  const DependAccountScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      DependencyScope<AccountContainer, AccountFactory>(
        factory: _factory,
        placeholder: const Text('loading'),
        errorBuilder: (error) => Text('error: $error'),
        builder: (context) => Text(
          'ready: ${DependencyProvider.of<AccountContainer>(context).session.user}',
        ),
      );
}
