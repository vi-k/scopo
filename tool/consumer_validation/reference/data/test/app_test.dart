import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_exercise/app.dart';
import 'package:resource_exercise/backend.dart';

Future<void> advance(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 10),
        ));
    await tester.pump();
  }
  expect(done(), isTrue);
}

void main() {
  testWidgets('unrelated app rebuild keeps the acquired instance',
      (tester) async {
    final backend = Backend();
    await tester.pumpWidget(buildApp(backend));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pump();
    await advance(tester, () => find.text('Data a').evaluate().isNotEmpty);
    await tester.pumpWidget(buildApp(backend));
    expect(find.text('Data a'), findsOneWidget);
    expect(backend.events.where((e) => e == 'open:a'), hasLength(1));
    expect(backend.events.where((e) => e == 'use:a:mount'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await advance(tester, () => backend.liveResources == 0);
    expect(backend.events.where((e) => e == 'close:a'), hasLength(1));
    expect(backend.useAfterClose, 0);
    expect(tester.takeException(), isNull);
  });
}
