import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/home/demos/async_scope/counter_scope.dart';

Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    final previousPause = ScopeConfig.pauseAfterInitializationEnabled;
    ScopeConfig.pauseAfterInitializationEnabled = false;
    addTearDown(
      () => ScopeConfig.pauseAfterInitializationEnabled = previousPause,
    );
  });

  testWidgets('CounterScope.countOf follows model increments', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _advance(tester);
    });
    late CounterModel model;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CounterScope(
            debugSource: 'countOf test',
            debugName: 'counter',
            childScope: Builder(
              builder: (context) {
                model = CounterScope.of(context);
                return Text('selected: ${CounterScope.countOf(context)}');
              },
            ),
          ),
        ),
      ),
    );
    await _advance(tester);
    expect(find.text('selected: 0'), findsOneWidget);

    model.increment();
    await tester.pump();
    expect(find.text('selected: 1'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pump();
    expect(find.text('selected: 2'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _advance(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CounterScope.of does not rebuild a consumer on increment',
      (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _advance(tester);
    });
    late CounterModel model;
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CounterScope(
            debugSource: 'read test',
            debugName: 'counter',
            childScope: Builder(
              builder: (context) {
                builds++;
                model = CounterScope.of(context);
                return Text('unselected: ${model.count}');
              },
            ),
          ),
        ),
      ),
    );
    await _advance(tester);
    final initialBuilds = builds;
    expect(initialBuilds, isPositive);
    expect(find.text('unselected: 0'), findsOneWidget);

    model.increment();
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('unselected: 0'), findsOneWidget);
    expect(builds, initialBuilds);

    await tester.pumpWidget(const SizedBox.shrink());
    await _advance(tester);
    expect(tester.takeException(), isNull);
  });
}
