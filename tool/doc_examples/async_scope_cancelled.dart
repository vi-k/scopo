import 'manifest.dart';

/// Runs `describe` from the error screen recipe on what a real `AsyncScope`
/// hands its `errorBuilder`.
const describeCancelled = DocExecution(
  '''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';
''',
  '''

Future<String> shown(
  WidgetTester tester,
  Future<void> Function(ScopeInitContext ctx) body,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AsyncScope(
        initScope: (context, ctx) => body(ctx),
        disposeScope: () {},
        progressBuilder: (context, progress) => const Text('loading'),
        errorBuilder: (context, error, stackTrace, progress) =>
            Text(describe(error)),
        builder: (context) => const Text('ready'),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  final text = tester.widget<Text>(find.byType(Text)).data!;
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
  return text;
}

DeferredJob<void> parked({Duration? timeout}) => Job.deferred<void>(
  timeout: timeout,
  (ctx) => ctx.abandonable(() => Completer<void>().future),
);

void main() {
  testWidgets('describe reads what the error screen receives', (
    tester,
  ) async {
    expect(
      await shown(tester, (ctx) async => throw const Cancelled('no session')),
      'no session',
    );
    expect(
      await shown(tester, (ctx) async {
        await ctx.run(parked(timeout: const Duration(seconds: 1)));
      }),
      'No answer in 1 s',
    );
    expect(
      await shown(tester, (ctx) async {
        final child = parked();
        unawaited(Future<void>(child.cancel));
        await ctx.run(child);
      }),
      'Stopped',
    );
    expect(
      await shown(tester, (ctx) async => throw StateError('offline')),
      'Failed: Bad state: offline',
    );
  });
}
''',
);
