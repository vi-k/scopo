// Most of what this file checks is that it compiles.
//
// A mocking package builds its double one way -- `class MockX extends Mock
// implements X` -- and three class modifiers forbid exactly that: `final`,
// `base` and `sealed`. The types below are the ones a consumer writes tests
// against, so each one is declared here the way `mocktail` would declare it.
// Put `base` back on any of them and this file stops compiling, which is the
// whole point: the promise is a compile-time one, and only a compile-time
// check can hold it.
//
// The second half matters more than the first. A `base` class does not only
// refuse to be implemented, it obliges every subclass to be `base` or
// `final` -- so the modifier on our class is what used to forbid mocking the
// consumer's own class built on top of it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  test('the types a consumer tests against can be mocked', () {
    // Ours.
    expect(_MockObserver(), isA<ScopeObserver>());
    expect(_MockNotifier(), isA<ScopeStateNotifier<int>>());
    expect(_MockModelView(), isA<ScopeStateModelView<int>>());
    expect(_MockErrorNotifier(), isA<ScopeStateWithErrorNotifier<int>>());
    expect(_MockErrorModelView(), isA<ScopeStateWithErrorModelView<int>>());
    expect(_MockListenableView(), isA<ListenableView<Listenable>>());
    expect(_MockHandle(), isA<ScopeDependencyHandle>());

    // And theirs, built on ours -- the half `base` used to take away.
    expect(_MockAppController(), isA<_AppController>());
    expect(_MockAppDependencies(), isA<_AppDependencies>());
  });

  // The half that compiling does not show. A double is mockable only if the
  // thing that drives it accepts one, and the scope that owns a controller
  // used to refuse: its freshness check read state private to
  // `ScopeController`, which a double built by `implements` has none of.
  testWidgets('a mocked controller is accepted by the scope that owns one',
      (tester) async {
    final controller = _MockAppController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AsyncControllerScope<_AppController>(
          createController: (context) => controller,
          progressBuilder: (context) => const Text('progress'),
          errorBuilder: (context, error, stackTrace) => Text('error: $error'),
          builder: (context, controller) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(controller.calls, [#performInit]);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(
      tester,
      until: () => controller.calls.contains(#performDispose),
    );

    expect(
      controller.calls,
      containsAllInOrder([#performInit, #performUnmount, #performDispose]),
      reason: 'the scope drives a double through the same three wrappers',
    );
  });
}

/// Stands in for `Mock` of `mocktail`: the base a double extends while it
/// implements the type under test. A class that inherits a `noSuchMethod`
/// other than `Object`'s is allowed to leave the interface unimplemented,
/// which is how every mocking package in Dart works.
class _Mock {
  /// What the double was asked for, in order.
  final calls = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);

    // Stands in for `thenAnswer((_) async {})`: the two wrappers that return
    // a future are awaited by whoever drives the controller, and `null` in
    // their place fails the cast before anything else can happen.
    return invocation.memberName == #performInit ||
            invocation.memberName == #performDispose
        ? Future<void>.value()
        : null;
  }
}

// The consumer's own classes, and the point of the second half: both are
// plain classes. While ours were `base`, these two could not be -- the
// language obliged them to be `base` or `final` themselves, and either one
// refuses `implements`, so the application could not mock its own controller
// or its own container. Declaring them plainly is the freedom being bought
// here; mocking them below is what it is bought for.

class _AppController extends ScopeController {
  @override
  Future<void> init() async {}
}

class _AppDependencies extends ScopeAutoDependencies<_AppDependencies, void> {
  @override
  ScopeDependency buildDependencies(void context) => sequential('', []);
}

class _MockAppController extends _Mock implements _AppController {}

class _MockAppDependencies extends _Mock implements _AppDependencies {}

class _MockObserver extends _Mock implements ScopeObserver {}

class _MockNotifier extends _Mock implements ScopeStateNotifier<int> {}

class _MockModelView extends _Mock implements ScopeStateModelView<int> {}

class _MockErrorNotifier extends _Mock
    implements ScopeStateWithErrorNotifier<int> {}

class _MockErrorModelView extends _Mock
    implements ScopeStateWithErrorModelView<int> {}

class _MockListenableView extends _Mock implements ListenableView<Listenable> {}

class _MockHandle extends _Mock implements ScopeDependencyHandle {}
