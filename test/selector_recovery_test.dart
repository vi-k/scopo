import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  for (final catchError in [false, true]) {
    testWidgets(
      catchError
          ? 'a caught selector error keeps the consumer subscribed'
          : 'a selector error shown by ErrorWidget keeps the consumer subscribed',
      (tester) async {
        final model = _RecoverableCounter();
        addTearDown(model.dispose);
        var stateBuilds = 0;
        var constantBuilds = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ScopeNotifier<_RecoverableCounter>.value(
              value: model,
              builder: (context) => Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        stateBuilds++;
                        try {
                          final state =
                              ScopeNotifier.select<_RecoverableCounter, int>(
                                context,
                                (model) => model.state,
                              );

                          return Text('state: $state');
                        } on Exception {
                          if (!catchError) {
                            rethrow;
                          }

                          return const Text('failed');
                        }
                      },
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      constantBuilds++;
                      final constant =
                          ScopeNotifier.select<_RecoverableCounter, int>(
                            context,
                            (model) => model.constant,
                          );

                      return Text('constant: $constant');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        expect(find.text('state: 0'), findsOneWidget);
        expect(find.text('constant: 42'), findsOneWidget);
        expect(constantBuilds, 1);

        final failure = Exception('temporary selector failure');
        final reported = <Object>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) => reported.add(details.exception);
        try {
          model.setError(failure, StackTrace.current);
          await tester.pump();
        } finally {
          FlutterError.onError = previous;
        }

        expect(reported, hasLength(catchError ? 1 : 2));
        expect(reported, everyElement(same(failure)));
        expect(
          find.byType(ErrorWidget),
          catchError ? findsNothing : findsOneWidget,
        );
        expect(find.text('failed'), catchError ? findsOneWidget : findsNothing);
        expect(constantBuilds, 1);

        model.update(1);
        await tester.pumpAndSettle();

        expect(find.text('state: 1'), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(find.text('failed'), findsNothing);
        expect(constantBuilds, 1);

        model.update(2);
        await tester.pump();

        expect(find.text('state: 2'), findsOneWidget);
        expect(stateBuilds, 4);
        expect(
          constantBuilds,
          1,
          reason: 'a failing neighbour does not broaden this selection',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final class _RecoverableCounter extends ScopeStateWithErrorNotifier<int> {
  _RecoverableCounter() : super(0);

  int get constant => 42;
}
