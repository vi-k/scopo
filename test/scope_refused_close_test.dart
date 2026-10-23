import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  testWidgets('Scope retains the ready subtree after a refused close()',
      (tester) async {
    final closeNow = ValueNotifier(false);
    addTearDown(closeNow.dispose);
    final state = _RefusedCloseState();
    final dependencies = _Dependencies();
    Object? refusal;

    Widget app() => MaterialApp(
          home: _RefusedCloseScope(
            state,
            dependencies,
            ListenableBuilder(
              listenable: closeNow,
              builder: (context, child) {
                if (closeNow.value) {
                  state.close().onError((error, stackTrace) {
                    refusal = error;
                  });
                }

                return const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('ready'),
                );
              },
            ),
          ),
        );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    closeNow.value = true;
    await tester.pump();
    expect(refusal, isFlutterError);

    closeNow.value = false;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    try {
      expect(find.text('ready'), findsOneWidget);
      expect(find.text('closing'), findsNothing);
      expect(state.releases, 0);
      expect(dependencies.releases, 0);
      expect(state.mounted, isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester, until: () => dependencies.releases == 1);
    }
    expect(state.releases, 1);
    expect(dependencies.releases, 1);
  });
}

final class _RefusedCloseScope
    extends Scope<_RefusedCloseScope, _Dependencies, _RefusedCloseState> {
  final _RefusedCloseState state;
  final _Dependencies dependencies;
  final Widget body;

  const _RefusedCloseScope(this.state, this.dependencies, this.body);

  @override
  Future<_Dependencies> initDependencies(
    BuildContext context,
    ScopeInitContext ctx,
  ) async =>
      dependencies;

  @override
  _RefusedCloseState createState() => state;

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      const Text('error');

  @override
  Widget? buildOnClosing(BuildContext context) => const Text('closing');
}

final class _RefusedCloseState
    extends ScopeState<_RefusedCloseScope, _Dependencies, _RefusedCloseState> {
  int releases = 0;

  @override
  Widget build(BuildContext context) => params.body;

  @override
  void disposeStateAsync() => releases++;
}

final class _Dependencies implements ScopeDependencies {
  int releases = 0;

  @override
  void onUnmount() {}

  @override
  void dispose() => releases++;
}
