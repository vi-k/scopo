import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_exercise/app.dart';
import 'package:resource_exercise/backend.dart';

Finder keyed(String name) => find.byKey(ValueKey<String>(name));

Future<void> tick(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 5),
      ));
  await tester.pump();
}

Future<void> until(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  for (var attempt = 0; attempt < 200 && !condition(); attempt++) {
    await tick(tester);
  }
  expect(condition(), isTrue, reason: description);
}

Future<void> quiet(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tick(tester);
  }
}

Future<void> press(WidgetTester tester, String name, String label) async {
  expect(keyed(name), findsOneWidget);
  final button = tester.widget<TextButton>(keyed(name));
  expect(button.onPressed, isNotNull);
  expect(find.descendant(of: keyed(name), matching: find.text(label)),
      findsOneWidget);
  await tester.tap(keyed(name));
  await tester.pump();
}

void screen(String name) {
  expect(keyed(name), findsOneWidget);
  for (final other in ['home', 'loading', 'error', 'closing']) {
    if (other != name) expect(keyed(other), findsNothing);
  }
  if (name != 'ready') expect(find.byType(ResourceChild), findsNothing);
}

Future<void> start(WidgetTester tester, Backend backend) async {
  await tester.pumpWidget(buildApp(backend));
  screen('home');
  expect(backend.events, isEmpty);
  await press(tester, 'open', 'Open');
  screen('loading');
  expect(find.text('Loading a'), findsOneWidget);
  await until(tester, () => backend.events.contains('open:a'), 'open a starts');
  expect(backend.events, ['open:a']);
}

Future<void> ready(WidgetTester tester, Backend backend, String id) async {
  backend.releaseOpen(id);
  await until(tester, () => keyed('data').evaluate().isNotEmpty, 'data $id');
  expect(find.text('Data $id'), findsOneWidget);
  expect(find.byType(ResourceChild), findsOneWidget);
  final child = tester.widget<ResourceChild>(find.byType(ResourceChild));
  expect(child.resource.id, id);
  for (final name in ['home', 'loading', 'error', 'closing']) {
    expect(keyed(name), findsNothing);
  }
  expect(backend.liveResources, 1);
}

Future<void> finishClose(
    WidgetTester tester, Backend backend, String id) async {
  await until(tester, () => backend.events.contains('close:$id'), 'close $id');
  backend.releaseClose(id);
  await until(tester, () => backend.liveResources == 0, 'release $id');
  await quiet(tester);
  expect(backend.useAfterClose, 0);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Close waits for release after the child finishes using data',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await quiet(tester);
    expect(backend.events, ['open:a']);
    await ready(tester, backend, 'a');
    await press(tester, 'use', 'Use');
    await press(tester, 'close', 'Close');
    screen('closing');
    expect(find.text('Closing'), findsOneWidget);
    for (final name in ['leave', 'switch', 'close', 'use', 'open', 'retry']) {
      expect(keyed(name), findsNothing);
    }
    await until(
        tester, () => backend.events.contains('close:a'), 'close starts');
    // The Closing screen must outlive the coordinator's default wait limit.
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 3200),
        ));
    await quiet(tester);
    screen('closing');
    expect(backend.events, [
      'open:a',
      'opened:a',
      'use:a:mount',
      'use:a:tap',
      'use:a:dispose',
      'close:a',
    ]);
    await finishClose(tester, backend, 'a');
    screen('home');
    expect(backend.events.last, 'closed:a');
    await tester.pumpWidget(const SizedBox.shrink());
    await quiet(tester);
    expect(backend.events.where((e) => e == 'close:a'), hasLength(1));
  });

  testWidgets(
      'Leave during opening releases the late result without mounting it',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await press(tester, 'leave', 'Leave');
    screen('home');
    await quiet(tester);
    expect(backend.events, ['open:a']);
    backend.releaseOpen('a');
    await finishClose(tester, backend, 'a');
    screen('home');
    expect(backend.events, ['open:a', 'opened:a', 'close:a', 'closed:a']);
  });

  testWidgets(
      'Retry shows the real failure and acquires the same id once again',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true)
      ..failNextOpen('a');
    await start(tester, backend);
    backend.releaseOpen('a');
    await until(
        tester, () => keyed('error').evaluate().isNotEmpty, 'open error');
    screen('error');
    expect(find.text('Open failed a'), findsOneWidget);
    expect(find.textContaining('Cannot open a'), findsOneWidget);
    expect(backend.liveResources, 0);
    await press(tester, 'retry', 'Retry');
    screen('loading');
    await until(tester, () => backend.events.length == 3, 'retry starts');
    expect(backend.events, ['open:a', 'failed:a', 'open:a']);
    await ready(tester, backend, 'a');
    await press(tester, 'leave', 'Leave');
    screen('home');
    await finishClose(tester, backend, 'a');
    expect(backend.events.where((e) => e == 'close:a'), hasLength(1));
  });

  testWidgets('Leave after an error returns home and a fresh Open selects a',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true)
      ..failNextOpen('a');
    await start(tester, backend);
    backend.releaseOpen('a');
    await until(tester, () => keyed('error').evaluate().isNotEmpty, 'error');
    await press(tester, 'leave', 'Leave');
    screen('home');
    await press(tester, 'open', 'Open');
    await until(tester, () => backend.events.length == 3, 'new opening');
    await ready(tester, backend, 'a');
    await press(tester, 'close', 'Close');
    await finishClose(tester, backend, 'a');
    screen('home');
  });

  testWidgets('Switch waits for old release and each press alternates the id',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'switch', 'Switch');
    screen('loading');
    expect(find.text('Loading b'), findsOneWidget);
    await until(tester, () => backend.events.contains('close:a'), 'close a');
    await quiet(tester);
    expect(backend.events, [
      'open:a',
      'opened:a',
      'use:a:mount',
      'use:a:dispose',
      'close:a',
    ]);
    backend.releaseClose('a');
    await until(tester, () => backend.events.contains('open:b'), 'open b');
    expect(backend.events.indexOf('closed:a'),
        lessThan(backend.events.indexOf('open:b')));
    expect(backend.liveResources, 0);
    await ready(tester, backend, 'b');
    await press(tester, 'switch', 'Switch');
    expect(find.text('Loading a'), findsOneWidget);
    await until(tester, () => backend.events.contains('close:b'), 'close b');
    await quiet(tester);
    expect(backend.events.where((e) => e == 'open:a'), hasLength(1));
    backend.releaseClose('b');
    await until(
        tester,
        () => backend.events.where((e) => e == 'open:a').length == 2,
        'reopen a');
    await ready(tester, backend, 'a');
    await press(tester, 'close', 'Close');
    await until(
        tester,
        () => backend.events.where((e) => e == 'close:a').length == 2,
        'close a');
    backend.releaseClose('a');
    await until(tester, () => keyed('home').evaluate().isNotEmpty, 'home');
    expect(backend.liveResources, 0);
    expect(backend.useAfterClose, 0);
    expect(backend.events.where((e) => e == 'open:b'), hasLength(1));
    expect(backend.events.where((e) => e == 'closed:a'), hasLength(2));
    expect(backend.events.where((e) => e == 'closed:b'), hasLength(1));
  });

  testWidgets('Leave while waiting for replacement cancels the queued open',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'switch', 'Switch');
    await until(tester, () => backend.events.contains('close:a'), 'close a');
    await press(tester, 'leave', 'Leave');
    screen('home');
    await finishClose(tester, backend, 'a');
    expect(backend.events, [
      'open:a',
      'opened:a',
      'use:a:mount',
      'use:a:dispose',
      'close:a',
      'closed:a',
    ]);
  });

  testWidgets('Reopening from home waits for the departed owner to release',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'leave', 'Leave');
    screen('home');
    await until(tester, () => backend.events.contains('close:a'), 'release a');
    await press(tester, 'open', 'Open');
    screen('loading');
    await quiet(tester);
    expect(backend.events.where((e) => e == 'open:a'), hasLength(1));
    backend.releaseClose('a');
    await until(
        tester,
        () => backend.events.where((e) => e == 'open:a').length == 2,
        'reopen a');
    await ready(tester, backend, 'a');
    await tester.pumpWidget(const SizedBox.shrink());
    await until(
        tester,
        () => backend.events.where((e) => e == 'close:a').length == 2,
        'unmount');
    backend.releaseClose('a');
    await until(tester, () => backend.liveResources == 0, 'unmount release');
    expect(backend.useAfterClose, 0);
    expect(backend.events.where((e) => e == 'use:a:dispose'), hasLength(2));
    expect(backend.events.where((e) => e == 'closed:a'), hasLength(2));
  });

  testWidgets('Unmount while opening still releases the eventual resource',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await tester.pumpWidget(const SizedBox.shrink());
    backend.releaseOpen('a');
    await finishClose(tester, backend, 'a');
    expect(backend.events, ['open:a', 'opened:a', 'close:a', 'closed:a']);
  });

  testWidgets('Failure arriving after Leave is handled without a late screen',
      (tester) async {
    final backend = Backend(holdOpens: true)..failNextOpen('a');
    await start(tester, backend);
    await press(tester, 'leave', 'Leave');
    backend.releaseOpen('a');
    await until(
        tester, () => backend.events.contains('failed:a'), 'late error');
    await quiet(tester);
    screen('home');
    expect(backend.events, ['open:a', 'failed:a']);
    expect(backend.liveResources, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A failed switch retries b and a later Open starts over at a',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true)
      ..failNextOpen('b');
    await start(tester, backend);
    await ready(tester, backend, 'a');
    await press(tester, 'switch', 'Switch');
    await finishClose(tester, backend, 'a');
    await until(tester, () => backend.events.contains('open:b'), 'opening b');
    backend.releaseOpen('b');
    await until(tester, () => keyed('error').evaluate().isNotEmpty, 'b error');
    screen('error');
    expect(find.text('Open failed b'), findsOneWidget);
    expect(find.textContaining('Cannot open b'), findsOneWidget);
    await press(tester, 'retry', 'Retry');
    screen('loading');
    expect(find.text('Loading b'), findsOneWidget);
    await until(
        tester,
        () => backend.events.where((e) => e == 'open:b').length == 2,
        'retry b');
    await ready(tester, backend, 'b');
    await press(tester, 'close', 'Close');
    await finishClose(tester, backend, 'b');
    screen('home');
    await press(tester, 'open', 'Open');
    expect(find.text('Loading a'), findsOneWidget);
    await until(
        tester,
        () => backend.events.where((e) => e == 'open:a').length == 2,
        'fresh a');
    await ready(tester, backend, 'a');
    await press(tester, 'leave', 'Leave');
    await until(
        tester,
        () => backend.events.where((e) => e == 'close:a').length == 2,
        'leave a');
    backend.releaseClose('a');
    await until(tester, () => backend.liveResources == 0, 'final release');
    expect(backend.useAfterClose, 0);
    expect(backend.events.where((e) => e == 'close:b'), hasLength(1));
    expect(backend.events.where((e) => e == 'closed:a'), hasLength(2));
  });

  testWidgets('Long opening and closing cannot let a replacement overlap',
      (tester) async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    await start(tester, backend);
    await press(tester, 'leave', 'Leave');
    await press(tester, 'open', 'Open');
    // Exceed scopo's documented default cancellation/key/disposal limits.
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 3200),
        ));
    await quiet(tester);
    screen('loading');
    expect(backend.events, ['open:a']);
    expect(tester.takeException(), isNull);
    backend.releaseOpen('a');
    await until(
        tester, () => backend.events.contains('close:a'), 'late release');
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 3200),
        ));
    await quiet(tester);
    screen('loading');
    expect(backend.events, ['open:a', 'opened:a', 'close:a']);
    expect(backend.liveResources, 1);
    expect(tester.takeException(), isNull);
    backend.releaseClose('a');
    await until(tester,
        () => backend.events.where((e) => e == 'open:a').length == 2, 'next a');
    expect(backend.events, [
      'open:a',
      'opened:a',
      'close:a',
      'closed:a',
      'open:a',
    ]);
    await ready(tester, backend, 'a');
    await press(tester, 'close', 'Close');
    await until(tester,
        () => backend.events.where((e) => e == 'close:a').length == 2, 'close');
    backend.releaseClose('a');
    await until(tester, () => keyed('home').evaluate().isNotEmpty, 'home');
    expect(backend.liveResources, 0);
    expect(backend.useAfterClose, 0);
  });

  testWidgets('Normal backend delays support repeated Open and Close cycles',
      (tester) async {
    final backend = Backend();
    await tester.pumpWidget(buildApp(backend));
    for (var cycle = 0; cycle < 3; cycle++) {
      screen('home');
      await press(tester, 'open', 'Open');
      screen('loading');
      await until(tester, () => keyed('data').evaluate().isNotEmpty, 'ready');
      expect(find.text('Data a'), findsOneWidget);
      await press(tester, 'use', 'Use');
      await press(tester, 'close', 'Close');
      screen('closing');
      await until(tester, () => keyed('home').evaluate().isNotEmpty, 'home');
      expect(backend.liveResources, 0);
    }
    expect(backend.events, [
      for (var cycle = 0; cycle < 3; cycle++) ...[
        'open:a',
        'opened:a',
        'use:a:mount',
        'use:a:tap',
        'use:a:dispose',
        'close:a',
        'closed:a',
      ],
    ]);
    expect(backend.useAfterClose, 0);
    expect(tester.takeException(), isNull);
  });
}
