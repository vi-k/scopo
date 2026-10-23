import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  testWidgets('paused retries still wait for frames until removal',
      (tester) async {
    final events = <String>[];
    final binding = tester.binding;
    try {
      await tester.pumpWidget(
        _app(
          Offstage(
            child: ScreenshotReplacer(
              onCompleted: () => events.add('completed'),
              child: _Child(onDispose: () => events.add('child.dispose')),
            ),
          ),
        ),
      );
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(binding.framesEnabled, isFalse);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.idle();
      expect(events, isEmpty);
      expect(find.byType(_Child, skipOffstage: false), findsOneWidget);

      await tester.pumpWidget(_app(const SizedBox.shrink()));
      expect(events, ['child.dispose', 'completed']);
    } finally {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
  });

  for (final pauseBeforeImage in [false, true]) {
    testWidgets(
      'applies a pending replacement without enabled frames '
      '(pauseBeforeImage=$pauseBeforeImage)',
      (tester) async {
        final events = <String>[];
        final binding = tester.binding;
        try {
          await tester.pumpWidget(
            _app(
              ScreenshotReplacer(
                onCompleted: () => events.add('completed'),
                child: _Child(onDispose: () => events.add('child.dispose')),
              ),
            ),
          );
          if (!pauseBeforeImage) {
            // Let toImage finish without drawing the replacement frame.
            final element = tester.element(find.byType(ScreenshotReplacer));
            for (var i = 0; i < 20 && !element.dirty; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
              await tester.idle();
            }
            expect(element.dirty, isTrue, reason: 'the image has arrived');
          }
          binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
          expect(binding.framesEnabled, isFalse);

          // No pump: that would supply the very frame that a paused app lacks.
          for (var i = 0; i < 20 && !events.contains('completed'); i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.idle();
          }

          expect(events, ['child.dispose', 'completed']);
          expect(find.byType(RawImage), findsOneWidget);
        } finally {
          binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await tester.pumpWidget(_app(const SizedBox.shrink()));
        }
      },
    );
  }

  for (final offstage in [false, true]) {
    testWidgets(
      'completion follows child disposal (offstage=$offstage)',
      (tester) async {
        final events = <String>[];
        await tester.pumpWidget(
          _app(
            Offstage(
              offstage: offstage,
              child: ScreenshotReplacer(
                onCompleted: () => events.add('completed'),
                child: _Child(onDispose: () => events.add('child.dispose')),
              ),
            ),
          ),
        );

        await settle(tester, until: () => events.contains('completed'));

        expect(events, ['child.dispose', 'completed']);
        expect(
          find.byType(RawImage, skipOffstage: false),
          offstage ? findsNothing : findsOneWidget,
        );
        await tester.pumpWidget(_app(const SizedBox.shrink()));
        expect(events, ['child.dispose', 'completed']);
      },
    );

    testWidgets(
      'removal during capture completes once (offstage=$offstage)',
      (tester) async {
        final events = <String>[];
        await tester.pumpWidget(
          _app(
            Offstage(
              offstage: offstage,
              child: ScreenshotReplacer(
                onCompleted: () => events.add('completed'),
                child: _Child(onDispose: () => events.add('child.dispose')),
              ),
            ),
          ),
        );

        await tester.pumpWidget(_app(const SizedBox.shrink()));
        // Let an in-flight toImage finish after disposal, then run any stale
        // post-frame callback as well.
        await settle(tester, until: () => false, rounds: 3);

        expect(events, ['child.dispose', 'completed']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _app(Widget child) => MaterialApp(home: Center(child: child));

class _Child extends StatefulWidget {
  final VoidCallback onDispose;

  const _Child({required this.onDispose});

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20);
}
