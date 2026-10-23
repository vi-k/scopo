import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickstart/main.dart';

void main() {
  testWidgets('loads, becomes ready, and closes before acquiring again',
      (tester) async {
    LocalResource.events.clear();
    await tester.pumpWidget(const QuickstartApp());
    await tester.pump();

    expect(find.text('Loading 1'), findsOneWidget);
    expect(find.text('Ready 1'), findsNothing);
    await _advance(tester);
    expect(find.text('Ready 1'), findsOneWidget);
    expect(LocalResource.events, ['opening 1', 'opened 1']);

    await tester.tap(find.text('Recreate scope'));
    await tester.pump();
    expect(find.text('Ready 1'), findsNothing);
    await _advance(tester);
    expect(find.text('Ready 2'), findsOneWidget);
    expect(LocalResource.events, [
      'opening 1',
      'opened 1',
      'closing 1',
      'closed 1',
      'opening 2',
      'opened 2',
    ]);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await _advance(tester);
    expect(
      LocalResource.events.sublist(LocalResource.events.length - 2),
      ['closing 2', 'closed 2'],
    );
  });
}

Future<void> _advance(WidgetTester tester) async {
  // Teardown also uses real futures. Advance both clocks, as in scopo_demo;
  // pumpAndSettle alone cannot drain the scope's asynchronous disposal.
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
}
