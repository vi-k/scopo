import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  for (final (name, build) in _asyncFamilies) {
    for (final afterDisposal in [false, true]) {
      testWidgets('$name diagnostics after unmount '
          '${afterDisposal ? 'after' : 'during'} disposal', (tester) async {
        final disposal = _Disposal();
        final scope = build(disposal);
        await tester.pumpWidget(_wrap(scope));
        await tester.pumpAndSettle();
        final element = tester.element(find.byWidget(scope));
        final coordinator = tester.element(find.byType(AsyncScopeCoordinator));
        final mountedDiagnostics = element.toDiagnosticsNode().toStringDeep();
        expect(mountedDiagnostics, contains('scopeKey: diagnostics-key'));
        expect(mountedDiagnostics, contains('pauseAfterInitialization:'));

        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
        await settle(tester, until: () => disposal.started);
        expect(disposal.started, isTrue);
        expect(disposal.finished, isFalse);
        expect(element.mounted, isFalse);

        Future<void> finishDisposal() async {
          disposal.gate.complete();
          await settle(tester, until: () => disposal.finished);
          expect(disposal.finished, isTrue);
          await tester.runAsync(
            () => AsyncScopeCoordinator.waitForChildren(coordinator),
          );
          await tester.pump();
        }

        if (afterDisposal) {
          await finishDisposal();
        }
        try {
          _expectPrintable(element);
          final diagnostics = element.toDiagnosticsNode().toStringDeep();
          expect(diagnostics, contains('state:'));
          expect(diagnostics, contains('model:'));
          expect(diagnostics, isNot(contains('scopeKey:')));
          expect(diagnostics, isNot(contains('pauseAfterInitialization:')));
          if (name == 'AsyncDataScope' || name == 'AsyncControllerScope') {
            expect(diagnostics, contains('data:'));
          }
          if (name == 'Scope') {
            expect(diagnostics, contains('dependencies:'));
          }
        } finally {
          if (!afterDisposal) {
            await finishDisposal();
          }
        }
      });
    }
  }

  for (final name in [
    'ScopeWidget',
    'AsyncScopeCoordinator',
    'ScopeModel',
    'ScopeModel.value',
    'ScopeNotifier',
    'ScopeNotifier.value',
  ]) {
    testWidgets('$name diagnostics after unmount', (tester) async {
      final notifier = ValueNotifier<int>(42);
      addTearDown(notifier.dispose);
      final Widget scope = switch (name) {
        'ScopeWidget' => const _WidgetScope(),
        'AsyncScopeCoordinator' => const AsyncScopeCoordinator(
          child: SizedBox.shrink(),
        ),
        'ScopeModel' => ScopeModel<String>(
          create: (_) => 'owned model',
          dispose: (_) {},
          builder: (_) => const SizedBox.shrink(),
        ),
        'ScopeModel.value' => ScopeModel<String>.value(
          value: 'borrowed model',
          builder: (_) => const SizedBox.shrink(),
        ),
        'ScopeNotifier' => ScopeNotifier<ValueNotifier<int>>(
          create: (_) => ValueNotifier<int>(42),
          dispose: (model) => model.dispose(),
          builder: (_) => const SizedBox.shrink(),
        ),
        'ScopeNotifier.value' => ScopeNotifier<ValueNotifier<int>>.value(
          value: notifier,
          builder: (_) => const SizedBox.shrink(),
        ),
        _ => throw StateError('Unknown family: $name'),
      };
      await tester.pumpWidget(scope);
      final element = tester.element(find.byWidget(scope));
      _expectPrintable(element);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(element.mounted, isFalse);
      _expectPrintable(element);
      if (name == 'ScopeModel' || name == 'ScopeNotifier') {
        expect(
          element.toDiagnosticsNode().toStringDeep(),
          contains('model:'),
          reason: 'an owned model is held by the element after unmount',
        );
      }
    });
  }

  testWidgets('missing create explains the scope, condition and remedy', (
    tester,
  ) async {
    await tester.pumpWidget(const _MissingCreateScope());
    final error = tester.takeException();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(error, isA<FlutterError>());
    final message = error.toString();
    expect(message, contains('_MissingCreateScope'));
    expect(message, contains('create'));
    expect(message, contains('hasValue'));
    expect(message, contains('null'));
    expect(message, contains('.value'));
    expect(message, contains('Pass'));
  });
}

void _expectPrintable(Element element) {
  expect(element.toString, returnsNormally);
  expect(() => element.toDiagnosticsNode().toStringDeep(), returnsNormally);
}

Widget _wrap(Widget child) => AsyncScopeCoordinator(child: child);

final class _Disposal {
  final gate = Completer<void>();
  bool started = false;
  bool finished = false;

  Future<void> dispose() async {
    started = true;
    await gate.future;
    finished = true;
  }
}

final List<(String, Widget Function(_Disposal))> _asyncFamilies = [
  (
    'AsyncScope',
    (disposal) => AsyncScope(
      scopeKey: 'diagnostics-key',
      pauseAfterInitialization: Duration.zero,
      initScope: (_, __) async {},
      disposeScope: disposal.dispose,
      progressBuilder: (_, __) => const SizedBox.shrink(),
      errorBuilder: (_, error, __, ___) => ErrorWidget(error),
      builder: (_) => const SizedBox.shrink(),
    ),
  ),
  (
    'AsyncDataScope',
    (disposal) => AsyncDataScope<String>(
      scopeKey: 'diagnostics-key',
      pauseAfterInitialization: Duration.zero,
      initData: (_, __) async => 'diagnostic data',
      disposeData: (_) => disposal.dispose(),
      progressBuilder: (_, __) => const SizedBox.shrink(),
      errorBuilder: (_, error, __, ___) => ErrorWidget(error),
      builder: (_, __) => const SizedBox.shrink(),
    ),
  ),
  (
    'AsyncControllerScope',
    (disposal) => AsyncControllerScope<_Controller>(
      scopeKey: 'diagnostics-key',
      pauseAfterInitialization: Duration.zero,
      createController: (_) => _Controller(disposal),
      progressBuilder: (_) => const SizedBox.shrink(),
      errorBuilder: (_, error, __) => ErrorWidget(error),
      builder: (_, __) => const SizedBox.shrink(),
    ),
  ),
  ('LiteScope', _LiteFixture.new),
  ('Scope', _ScopeFixture.new),
];

final class _Controller extends ScopeController {
  final _Disposal disposal;

  _Controller(this.disposal);

  @override
  Future<void> dispose() => disposal.dispose();
}

final class _LiteFixture extends LiteScope<_LiteFixture, _LiteFixtureState> {
  final _Disposal disposal;

  const _LiteFixture(this.disposal)
    : super(
        scopeKey: 'diagnostics-key',
        pauseAfterInitialization: Duration.zero,
      );

  @override
  Widget buildOnWaiting(BuildContext context) => const SizedBox.shrink();

  @override
  _LiteFixtureState createState() => _LiteFixtureState();
}

final class _LiteFixtureState
    extends LiteScopeState<_LiteFixture, _LiteFixtureState> {
  @override
  Future<void> disposeStateAsync() => params.disposal.dispose();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _ScopeFixture
    extends Scope<_ScopeFixture, _Dependencies, _ScopeFixtureState> {
  final _Disposal disposal;

  const _ScopeFixture(this.disposal)
    : super(
        scopeKey: 'diagnostics-key',
        pauseAfterInitialization: Duration.zero,
      );

  @override
  Future<_Dependencies> initDependencies(
    BuildContext context,
    ScopeInitContext ctx,
  ) async => _Dependencies();

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) => ErrorWidget(error);

  @override
  _ScopeFixtureState createState() => _ScopeFixtureState();
}

final class _ScopeFixtureState
    extends ScopeState<_ScopeFixture, _Dependencies, _ScopeFixtureState> {
  @override
  Future<void> disposeStateAsync() => params.disposal.dispose();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _Dependencies implements ScopeDependencies {
  @override
  void onUnmount() {}

  @override
  void dispose() {}
}

final class _WidgetScope extends ScopeWidgetBase<_WidgetScope> {
  const _WidgetScope();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _MissingCreateScope
    extends ScopeModelBase<_MissingCreateScope, Object> {
  const _MissingCreateScope() : super(create: _unusedCreate, dispose: null);

  static Object _unusedCreate(BuildContext context) => Object();

  @override
  Object Function(BuildContext)? get create => null;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
