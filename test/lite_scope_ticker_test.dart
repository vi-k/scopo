import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  for (final close in [false, true]) {
    testWidgets(
        'Child ticker owner disposes before its mixin '
        '(close=$close)', (tester) async {
      final state = _AnimationScopeState();
      await tester.pumpWidget(_app(_AnimationScope(state)));
      await settle(
        tester,
        until: () => find.byType(_AnimatedMark).evaluate().isNotEmpty,
      );
      final owner =
          tester.state<_AnimatedMarkState>(find.byType(_AnimatedMark));
      await tester.pump(const Duration(milliseconds: 10));
      expect(owner.controller.isAnimating, isTrue);

      if (close) {
        var closed = false;
        final closing = state.close().then((_) => closed = true);
        await settle(tester, until: () => closed && !owner.mounted);
        expect(closed, isTrue);
        await closing;
      } else {
        await tester.pumpWidget(_app(const SizedBox.shrink()));
      }

      expect(owner.mounted, isFalse);
      expect(owner.disposed, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester, until: () => false);
      expect(tester.takeException(), isNull);
    });
  }

  for (final single in [true, false]) {
    testWidgets(
        'Scope ticker mixin checks before onUnmount '
        '(single=$single)', (tester) async {
      final state = single ? _SingleTickerState() : _MultiTickerState();
      await tester.pumpWidget(_app(_UnsafeScope(state)));
      await settle(tester, until: () => state.controller != null);
      await tester.pump(const Duration(milliseconds: 10));
      expect(state.controller!.isAnimating, isTrue);

      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        await tester.pumpWidget(_app(const SizedBox.shrink()));
      } finally {
        FlutterError.onError = previous;
      }
      expect(errors, hasLength(1));
      expect(
        errors.map((error) => error.exception),
        contains(
          isA<FlutterError>().having(
            (error) => error.toString(),
            'message',
            contains('was disposed with an active Ticker'),
          ),
        ),
      );
      expect(state.disposedInOnUnmount, isTrue);
      await settle(tester, until: () => false);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(Widget child) => MaterialApp(home: Center(child: child));

final class _AnimationScope
    extends LiteScope<_AnimationScope, _AnimationScopeState> {
  final _AnimationScopeState instance;

  const _AnimationScope(this.instance);

  @override
  _AnimationScopeState createState() => instance;

  @override
  Widget buildOnWaiting(BuildContext context) => const SizedBox.shrink();
}

final class _AnimationScopeState
    extends LiteScopeState<_AnimationScope, _AnimationScopeState> {
  @override
  Widget build(BuildContext context) => const _AnimatedMark();
}

class _AnimatedMark extends StatefulWidget {
  const _AnimatedMark();

  @override
  State<_AnimatedMark> createState() => _AnimatedMarkState();
}

class _AnimatedMarkState extends State<_AnimatedMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  bool disposed = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    disposed = true;
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: controller,
        child: const SizedBox(width: 20, height: 20),
      );
}

final class _UnsafeScope extends LiteScope<_UnsafeScope, _UnsafeState> {
  final _UnsafeState instance;

  const _UnsafeScope(this.instance);

  @override
  _UnsafeState createState() => instance;

  @override
  Widget buildOnWaiting(BuildContext context) => const SizedBox.shrink();
}

abstract base class _UnsafeState
    extends LiteScopeState<_UnsafeScope, _UnsafeState>
    implements TickerProvider {
  AnimationController? controller;
  bool disposedInOnUnmount = false;

  @override
  void initStateAsync() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void onUnmount() {
    controller!.dispose();
    disposedInOnUnmount = true;
    super.onUnmount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20);
}

final class _SingleTickerState extends _UnsafeState
    with SingleTickerProviderStateMixin, _RecoverTickerDispose {}

final class _MultiTickerState extends _UnsafeState
    with TickerProviderStateMixin, _RecoverTickerDispose {}

// Record the real mixin failure without aborting Flutter's entire unmount walk.
// Stopping the ticker lets the retry finish; onUnmount still owns disposal.
mixin _RecoverTickerDispose<T extends StatefulWidget> on State<T> {
  AnimationController? get controller;

  @override
  void dispose() {
    try {
      super.dispose();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      controller!.stop();
      super.dispose();
    }
  }
}
