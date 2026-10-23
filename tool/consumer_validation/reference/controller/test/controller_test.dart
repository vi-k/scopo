import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_exercise/app.dart';
import 'package:resource_exercise/backend.dart';

Finder keyed(String name) => find.byKey(ValueKey<String>(name));

Future<void> tick(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 10)),
  );
  await tester.pump();
}

Future<void> until(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await tick(tester);
  }
  expect(condition(), isTrue);
}

Future<void> press(WidgetTester tester, String name) async {
  await tester.tap(keyed(name));
  await tester.pump();
}

void main() {
  testWidgets('reopening waits for a late owner to finish releasing',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await tester.pumpWidget(buildApp(backend));
    expect(keyed('open'), findsOneWidget);
    await press(tester, 'open');
    await until(tester, () => backend.events.contains('open:a'));

    await press(tester, 'leave');
    expect(keyed('home'), findsOneWidget);
    await press(tester, 'open');
    expect(keyed('loading'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tick(tester);
    }
    expect(backend.events, ['open:a']);

    backend.releaseOpen('a');
    await until(tester, () => backend.events.contains('close:a'));
    expect(backend.events.where((event) => event == 'open:a'), hasLength(1));
    expect(backend.events.where((event) => event.startsWith('use:')), isEmpty);
    backend.releaseClose('a');
    await until(tester,
        () => backend.events.where((event) => event == 'open:a').length == 2);
    expect(backend.events.indexOf('closed:a'),
        lessThan(backend.events.lastIndexOf('open:a')));

    backend.releaseOpen('a');
    await until(tester, () => keyed('data').evaluate().isNotEmpty);
    await press(tester, 'close');
    expect(keyed('closing'), findsOneWidget);
    await until(tester,
        () => backend.events.where((event) => event == 'close:a').length == 2);
    expect(backend.events.indexOf('use:a:dispose'),
        lessThan(backend.events.lastIndexOf('close:a')));
    backend.releaseClose('a');
    await until(tester, () => keyed('home').evaluate().isNotEmpty);
    expect(backend.liveResources, 0);
    expect(backend.useAfterClose, 0);
    expect(backend.events.where((event) => event == 'closed:a'), hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
