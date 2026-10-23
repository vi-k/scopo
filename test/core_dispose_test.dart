import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  for (final close in [false, true]) {
    final removal = close ? 'parent close' : 'tree removal';

    testWidgets('Data Core calls disposeData once on $removal', (tester) async {
      final disposed = <String?>[];
      final key = GlobalKey();
      final hostState = _ClosingState();
      final scope = _DataCore(
        key: key,
        init: (_) async => 'resource',
        dispose: disposed.add,
      );

      await tester.pumpWidget(
        close ? _ClosingHost(hostState, child: scope) : scope,
      );
      await tester.pumpAndSettle();
      final element = key.currentContext! as _DataElement;
      expect(element.data, 'resource');
      expect(disposed, isEmpty);

      if (close) {
        var closed = false;
        unawaited(hostState.close().then((_) => closed = true));
        await settle(tester, until: () => closed);
        expect(closed, isTrue);
        await hostState.close();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester, until: () => false, rounds: 2);

      expect(disposed, ['resource']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Controller Core calls disposeData once on $removal',
        (tester) async {
      final controller = _Controller();
      final disposed = <_Controller>[];
      final key = GlobalKey();
      final hostState = _ClosingState();
      final scope =
          _ControllerCore(key: key, controller: controller, disposed: disposed);

      await tester.pumpWidget(
        close ? _ClosingHost(hostState, child: scope) : scope,
      );
      await tester.pumpAndSettle();
      final element = key.currentContext! as _ControllerElement;
      expect(element.controller, same(controller));
      expect(controller.mounted, isTrue);
      expect(disposed, isEmpty);
      expect(controller.calls, ['init']);

      if (close) {
        var closed = false;
        unawaited(hostState.close().then((_) => closed = true));
        await settle(tester, until: () => closed);
        expect(closed, isTrue);
        await hostState.close();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester, until: () => false, rounds: 2);

      expect(disposed, [same(controller)]);
      expect(controller.calls, ['init', 'onUnmount', 'disposeData', 'dispose']);
      expect(controller.mounted, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Data Core disposes an accepted null value', (tester) async {
    final disposed = <String?>[];

    await tester.pumpWidget(
      _DataCore(init: (_) async => null, dispose: disposed.add),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => false, rounds: 2);

    expect(disposed, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Data Core disposes accepted data before the ready branch',
      (tester) async {
    final disposed = <String?>[];
    final key = GlobalKey();

    await tester.pumpWidget(
      _DataCore(
        key: key,
        init: (_) async => 'resource',
        dispose: disposed.add,
        pause: const Duration(seconds: 1),
      ),
    );
    await tester.pump();
    final element = key.currentContext! as _DataElement;
    expect(element.hasData, isTrue);
    expect(element.state, isNot(isA<AsyncScopeReady>()));

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => false, rounds: 2);

    expect(disposed, ['resource']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Controller Core disposes accepted data before the ready branch',
      (tester) async {
    final controller = _Controller();
    final disposed = <_Controller>[];
    final key = GlobalKey();

    await tester.pumpWidget(
      _ControllerCore(
        key: key,
        controller: controller,
        disposed: disposed,
        pause: const Duration(seconds: 1),
      ),
    );
    await tester.pump();
    final element = key.currentContext! as _ControllerElement;
    expect(element.hasController, isTrue);
    expect(element.state, isNot(isA<AsyncScopeReady>()));

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => false, rounds: 2);

    expect(disposed, [same(controller)]);
    expect(controller.calls, ['init', 'onUnmount', 'disposeData', 'dispose']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Data Core does not call disposeData after initialization fails',
      (tester) async {
    final failure = StateError('init failed');
    final disposed = <String?>[];
    final key = GlobalKey();

    await tester.pumpWidget(
      _DataCore(
        key: key,
        init: (_) async => throw failure,
        dispose: disposed.add,
      ),
    );
    await tester.pumpAndSettle();
    final element = key.currentContext! as _DataElement;
    expect(element.error, same(failure));
    expect(element.hasData, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => false, rounds: 2);

    expect(disposed, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Controller Core releases a failed init without disposeData',
      (tester) async {
    final failure = StateError('init failed');
    final controller = _Controller(failure: failure);
    final disposed = <_Controller>[];
    final key = GlobalKey();

    await tester.pumpWidget(
      _ControllerCore(key: key, controller: controller, disposed: disposed),
    );
    await settle(tester, until: () => controller.calls.contains('dispose'));
    await tester.pumpAndSettle();
    final element = key.currentContext! as _ControllerElement;
    expect(element.error, same(failure));
    expect(element.hasController, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => false, rounds: 2);

    expect(disposed, isEmpty);
    expect(controller.calls, ['init', 'onUnmount', 'dispose']);
    expect(tester.takeException(), isNull);
  });

  for (final abandon in [false, true]) {
    final arrival = abandon ? 'after teardown' : 'during cancellation';

    testWidgets('Data Core releases a late value once $arrival',
        (tester) async {
      final gate = Completer<String?>();
      final disposed = <String?>[];
      final key = GlobalKey();

      await tester.pumpWidget(
        _DataCore(
          key: key,
          init: (_) => gate.future,
          dispose: disposed.add,
          cancellationTimeout:
              abandon ? const Duration(milliseconds: 30) : null,
        ),
      );
      await tester.pump();
      final element = key.currentContext! as _DataElement;
      expect(element.hasData, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());

      if (abandon) {
        await settle(tester, until: () => false, rounds: 10);
        expect(tester.takeException(), isA<TimeoutException>());
      }
      expect(disposed, isEmpty);
      gate.complete('late resource');
      await settle(tester, until: () => disposed.isNotEmpty);
      await settle(tester, until: () => false, rounds: 2);

      expect(disposed, ['late resource']);
      expect(element.hasData, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Controller Core releases a late controller once $arrival',
        (tester) async {
      final gate = Completer<void>();
      final controller = _Controller(initGate: gate);
      final disposed = <_Controller>[];
      final key = GlobalKey();

      await tester.pumpWidget(
        _ControllerCore(
          key: key,
          controller: controller,
          disposed: disposed,
          cancellationTimeout:
              abandon ? const Duration(milliseconds: 30) : null,
        ),
      );
      await tester.pump();
      final element = key.currentContext! as _ControllerElement;
      expect(element.hasController, isFalse);
      expect(controller.calls, ['init']);
      await tester.pumpWidget(const SizedBox.shrink());

      if (abandon) {
        await settle(tester, until: () => false, rounds: 10);
        expect(tester.takeException(), isA<TimeoutException>());
      }
      expect(controller.calls, ['init', 'onUnmount']);
      gate.complete();
      await settle(tester, until: () => controller.calls.contains('dispose'));
      await settle(tester, until: () => false, rounds: 2);

      // This controller never became data: releaseLateData uses the guarded
      // release, just as it does after a failed initialization.
      expect(disposed, isEmpty);
      expect(controller.calls, ['init', 'onUnmount', 'dispose']);
      expect(element.hasController, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}

final class _DataCore
    extends AsyncDataScopeCore<_DataCore, _DataElement, String?> {
  final Future<String?> Function(ScopeInitContext ctx) init;
  final FutureOr<void> Function(String? data) dispose;
  final Duration? pause;
  final Duration? cancellationTimeout;

  const _DataCore({
    super.key,
    required this.init,
    required this.dispose,
    this.pause,
    this.cancellationTimeout,
  });

  @override
  _DataElement createScopeElement() => _DataElement(this);
}

final class _DataElement
    extends AsyncDataScopeElementBase<_DataCore, _DataElement, String?> {
  _DataElement(super.widget);

  @override
  Duration? get pauseAfterInitialization => widget.pause;

  @override
  Duration? get initCancellationTimeout => widget.cancellationTimeout;

  @override
  Future<String?> initDataAsync(ScopeInitContext ctx) => widget.init(ctx);

  @override
  FutureOr<void> disposeData(String? data) => widget.dispose(data);

  @override
  Widget buildOnState(AsyncScopeState state) => const SizedBox.expand();
}

final class _Controller extends ScopeController {
  final calls = <String>[];
  final Completer<void>? initGate;
  final Error? failure;

  _Controller({this.initGate, this.failure});

  @override
  Future<void> init() async {
    calls.add('init');
    await initGate?.future;
    if (failure case final failure?) {
      throw failure;
    }
  }

  @override
  void onUnmount() => calls.add('onUnmount');

  @override
  void dispose() => calls.add('dispose');
}

final class _ControllerCore extends AsyncControllerScopeCore<_ControllerCore,
    _ControllerElement, _Controller> {
  final _Controller controller;
  final List<_Controller> disposed;
  final Duration? pause;
  final Duration? cancellationTimeout;

  const _ControllerCore({
    super.key,
    required this.controller,
    required this.disposed,
    this.pause,
    this.cancellationTimeout,
  });

  @override
  _ControllerElement createScopeElement() => _ControllerElement(this);
}

final class _ControllerElement extends AsyncControllerScopeElementBase<
    _ControllerCore, _ControllerElement, _Controller> {
  _ControllerElement(super.widget);

  @override
  Duration? get pauseAfterInitialization => widget.pause;

  @override
  Duration? get initCancellationTimeout => widget.cancellationTimeout;

  @override
  _Controller createController(BuildContext context) => widget.controller;

  @override
  FutureOr<void> disposeData(_Controller data) {
    widget.disposed.add(data);
    data.calls.add('disposeData');

    return super.disposeData(data);
  }

  @override
  Widget buildOnState(AsyncScopeState state) => const SizedBox.expand();
}

// The Core families expose no close(): closing a LiteScope above them waits
// for their teardown through the child-scope registration.
final class _ClosingHost extends LiteScope<_ClosingHost, _ClosingState> {
  final _ClosingState scopeState;

  const _ClosingHost(this.scopeState, {required super.child});

  @override
  _ClosingState createState() => scopeState;

  @override
  Widget buildOnWaiting(BuildContext context) => const SizedBox.expand();

  @override
  Widget buildOnClosing(BuildContext context) => const SizedBox.expand();
}

final class _ClosingState extends LiteScopeState<_ClosingHost, _ClosingState> {
  @override
  Widget build(BuildContext context) => params.child;
}
