import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_exercise/app.dart';
import 'package:resource_exercise/backend.dart';

Finder keyed(String name) => find.byKey(ValueKey<String>(name));

Future<void> tick(WidgetTester tester, [int rounds = 1]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 10),
        ));
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> until(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await tick(tester);
  }
  expect(condition(), isTrue, reason: 'Condition did not become true');
}

Future<void> press(WidgetTester tester, String key) async {
  expect(keyed(key), findsOneWidget);
  await tester.tap(keyed(key));
  await tester.pump();
}

Future<void> start(WidgetTester tester, Backend backend) async {
  await tester.pumpWidget(buildApp(backend));
  expect(keyed('home'), findsOneWidget);
  await press(tester, 'open');
  await until(tester, () => backend.events.contains('open:a'));
}

Future<void> ready(WidgetTester tester, Backend backend, String id) async {
  backend.releaseOpen(id);
  await until(tester, () => keyed('data').evaluate().isNotEmpty);
  expect(find.text('Data $id'), findsOneWidget);
  expect(keyed('loading'), findsNothing);
  expect(keyed('error'), findsNothing);
  expect(keyed('home'), findsNothing);
  expect(backend.liveResources, 1);
  expect(backend.events.where((e) => e == 'use:$id:mount'), hasLength(1));
  await press(tester, 'use');
  expect(backend.events.last, 'use:$id:tap');
}

void before(Backend backend, String first, String second) {
  expect(backend.events, contains(first));
  expect(backend.events, contains(second));
  expect(
      backend.events.indexOf(first), lessThan(backend.events.indexOf(second)),
      reason: backend.events.join(', '));
}

Future<void> clean(WidgetTester tester, Backend backend) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 40; i++) {
    backend.releaseOpen('a');
    backend.releaseOpen('b');
    backend.releaseClose('a');
    backend.releaseClose('b');
    await tick(tester);
  }
  expect(backend.liveResources, 0, reason: backend.events.join(', '));
  expect(backend.useAfterClose, 0);
  for (final id in ['a', 'b']) {
    final opened = backend.events.where((e) => e == 'opened:$id').length;
    expect(backend.events.where((e) => e == 'close:$id'), hasLength(opened));
    expect(backend.events.where((e) => e == 'closed:$id'), hasLength(opened));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('d leave ready then immediate reopen waits for previous release',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'leave');
    expect(keyed('home'), findsOneWidget);
    await press(tester, 'open');
    await until(tester, () => backend.events.contains('close:a'));
    await tick(tester, 10);
    expect(keyed('loading'), findsOneWidget);
    expect(backend.events.where((e) => e == 'open:a'), hasLength(1));
    before(backend, 'use:a:dispose', 'close:a');
    backend.releaseClose('a');
    await until(
        tester, () => backend.events.where((e) => e == 'open:a').length == 2);
    expect(backend.events.indexOf('closed:a'),
        lessThan(backend.events.lastIndexOf('open:a')));
    backend.releaseOpen('a');
    await until(tester, () => find.text('Data a').evaluate().isNotEmpty);
    expect(backend.liveResources, 1);
    await clean(tester, backend);
  });

  testWidgets('b leave opening then immediate reopen keeps late owner isolated',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await press(tester, 'leave');
    await press(tester, 'open');
    await tick(tester, 10);
    expect(keyed('loading'), findsOneWidget);
    expect(backend.events, ['open:a']);
    backend.releaseOpen('a');
    await until(tester, () => backend.events.contains('close:a'));
    await tick(tester, 10);
    expect(backend.events.where((e) => e == 'open:a'), hasLength(1));
    expect(backend.events.where((e) => e.startsWith('use:')), isEmpty);
    backend.releaseClose('a');
    await until(
        tester, () => backend.events.where((e) => e == 'open:a').length == 2);
    await ready(tester, backend, 'a');
    before(backend, 'closed:a', 'use:a:mount');
    await clean(tester, backend);
  });

  testWidgets('d repeated switch back serializes both owners', (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'switch');
    await until(tester, () => backend.events.contains('close:a'));
    backend.releaseClose('a');
    await until(tester, () => backend.events.contains('open:b'));
    await ready(tester, backend, 'b');
    await press(tester, 'switch');
    await until(tester, () => backend.events.contains('close:b'));
    await tick(tester, 10);
    expect(backend.events.where((e) => e == 'open:a'), hasLength(1));
    expect(find.text('Loading a'), findsOneWidget);
    before(backend, 'use:b:dispose', 'close:b');
    backend.releaseClose('b');
    await until(
        tester, () => backend.events.where((e) => e == 'open:a').length == 2);
    expect(backend.events.indexOf('closed:b'),
        lessThan(backend.events.lastIndexOf('open:a')));
    backend.releaseOpen('a');
    await until(tester, () => find.text('Data a').evaluate().isNotEmpty);
    expect(backend.liveResources, 1);
    await clean(tester, backend);
  });

  testWidgets('e close then reopen acquires again', (tester) async {
    final backend = Backend(holdOpens: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'close');
    await until(tester, () => keyed('home').evaluate().isNotEmpty);
    expect(backend.events, contains('closed:a'));
    await press(tester, 'open');
    await until(
        tester, () => backend.events.where((e) => e == 'open:a').length == 2);
    backend.releaseOpen('a');
    await until(tester, () => find.text('Data a').evaluate().isNotEmpty);
    expect(backend.liveResources, 1);
    await clean(tester, backend);
  });

  testWidgets('a loading data and ordinary leave', (tester) async {
    final backend = Backend(holdOpens: true);
    await start(tester, backend);
    expect(keyed('loading'), findsOneWidget);
    expect(find.text('Loading a'), findsOneWidget);
    expect(keyed('data'), findsNothing);
    await tick(tester, 5);
    expect(backend.events, ['open:a']);
    await ready(tester, backend, 'a');
    await press(tester, 'leave');
    expect(keyed('home'), findsOneWidget);
    await until(tester, () => backend.events.contains('closed:a'));
    before(backend, 'use:a:dispose', 'close:a');
    await clean(tester, backend);
  });

  testWidgets('b leave while opening closes late resource', (tester) async {
    final backend = Backend(holdOpens: true);
    await start(tester, backend);
    await press(tester, 'leave');
    expect(keyed('home'), findsOneWidget);
    await tick(tester, 5);
    expect(backend.events, ['open:a']);
    backend.releaseOpen('a');
    await until(tester, () => backend.events.contains('closed:a'));
    expect(keyed('home'), findsOneWidget);
    expect(keyed('data'), findsNothing);
    expect(backend.events.where((e) => e.startsWith('use:')), isEmpty);
    await clean(tester, backend);
  });

  testWidgets('c visible error retry reacquires same id', (tester) async {
    final backend = Backend(holdOpens: true)..failNextOpen('a');
    await start(tester, backend);
    backend.releaseOpen('a');
    await until(tester, () => keyed('error').evaluate().isNotEmpty);
    expect(find.text('Open failed a'), findsOneWidget);
    expect(find.textContaining('Cannot open a'), findsOneWidget);
    expect(keyed('data'), findsNothing);
    await press(tester, 'retry');
    await until(
        tester, () => backend.events.where((e) => e == 'open:a').length == 2);
    expect(keyed('loading'), findsOneWidget);
    await ready(tester, backend, 'a');
    expect(backend.events.where((e) => e == 'failed:a'), hasLength(1));
    await clean(tester, backend);
  });

  testWidgets('d replacement waits for old close before new open',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'switch');
    await until(tester, () => backend.events.contains('close:a'));
    expect(keyed('loading'), findsOneWidget);
    expect(find.text('Loading b'), findsOneWidget);
    expect(keyed('data'), findsNothing);
    before(backend, 'use:a:dispose', 'close:a');
    await tick(tester, 10);
    expect(backend.events, isNot(contains('open:b')));
    backend.releaseClose('a');
    await until(tester, () => backend.events.contains('open:b'));
    before(backend, 'closed:a', 'open:b');
    await ready(tester, backend, 'b');
    await clean(tester, backend);
  });

  testWidgets('e close shows closing awaits release and removes child first',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'close');
    await until(tester, () => backend.events.contains('close:a'));
    expect(keyed('closing'), findsOneWidget);
    expect(find.text('Closing'), findsOneWidget);
    expect(keyed('home'), findsNothing);
    expect(keyed('data'), findsNothing);
    expect(keyed('use'), findsNothing);
    before(backend, 'use:a:dispose', 'close:a');
    await tick(tester, 10);
    expect(keyed('closing'), findsOneWidget);
    expect(keyed('home'), findsNothing);
    backend.releaseClose('a');
    await until(tester, () => keyed('home').evaluate().isNotEmpty);
    expect(backend.events, contains('closed:a'));
    expect(keyed('closing'), findsNothing);
    await clean(tester, backend);
  });

  testWidgets('a general root unmount releases ready resource', (tester) async {
    final backend = Backend();
    await start(tester, backend);
    await until(tester, () => keyed('data').evaluate().isNotEmpty);
    await clean(tester, backend);
    before(backend, 'use:a:dispose', 'close:a');
  });

  testWidgets('b general unmount before late acquisition', (tester) async {
    final backend = Backend(holdOpens: true);
    await start(tester, backend);
    await clean(tester, backend);
    expect(backend.events, contains('closed:a'));
  });

  testWidgets('c error leave and a reopen start a fresh owner', (tester) async {
    final backend = Backend(holdOpens: true)..failNextOpen('a');
    await start(tester, backend);
    backend.releaseOpen('a');
    await until(tester, () => keyed('error').evaluate().isNotEmpty);
    await press(tester, 'leave');
    expect(keyed('home'), findsOneWidget);
    await press(tester, 'open');
    await until(
        tester, () => backend.events.where((e) => e == 'open:a').length == 2);
    await ready(tester, backend, 'a');
    await clean(tester, backend);
  });
}
