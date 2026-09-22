import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/leaks.dart';

void main() {
  group('looking a scope up', () {
    testWidgets('maybeOf returns null when there is no such scope above', (
      tester,
    ) async {
      Object? found = 'untouched';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              found = ScopeWidgetCore.maybeOf<_Scope, _ScopeElement>(
                context,
                listen: false,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(found, isNull);
    });

    testWidgets('of names the scope it could not find', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              ScopeWidgetCore.of<_Scope, _ScopeElement>(
                context,
                listen: false,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<Exception>().having(
          (e) => '$e',
          'message',
          contains('_Scope not found in the context'),
        ),
      );
    });

    testWidgets('select fails the same way when the scope is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
                context,
                (element) => element.value,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<Exception>().having(
          (e) => '$e',
          'message',
          contains('_Scope not found in the context'),
        ),
      );
    });

    testWidgets(
        'a scope finds itself, and a listener of its own value is '
        'notified', (tester) async {
      await tester.pumpWidget(const _Host());
      await tester.pumpAndSettle();

      final scope = tester.element(find.byType(_Scope)) as _ScopeElement;

      expect(
        ScopeWidgetCore.maybeOf<_Scope, _ScopeElement>(
          scope,
          listen: false,
        ),
        same(scope),
        reason: 'the lookup starts at the element itself',
      );

      // A self-dependency: `InheritedElement` refuses to let an element depend
      // on itself, so the scope keeps those subscriptions apart. The value it
      // selects is its own, and it must still be told when that value changes.
      // A build first, so the subscription is taken where subscriptions are
      // taken; then the change it is meant to hear about.
      scope
        ..dependOnSelf = true
        ..markNeedsBuild();
      await tester.pump();

      scope.bump();
      await tester.pump();

      expect(scope.selfNotifications, 1);
    });

    // Flutter remembers a lookup that found nothing, so that a widget moved
    // under a matching ancestor later is told about it. The lookup here went
    // through `getElementForInheritedWidgetOfExactType`, which records
    // nothing, so a `GlobalKey` widget carried under a scope was never
    // notified: it went on showing what it read when there was no scope.
    testWidgets('a lookup that found nothing is remembered as a dependency', (
      tester,
    ) async {
      final key = GlobalKey();
      final seeker = _Seeker(key: key);

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: seeker),
      );

      final state = tester.state<_SeekerState>(find.byType(_Seeker));

      expect(state.found, isFalse);
      expect(state.dependencyChanges, 1, reason: 'the one after initState');

      // The same element, carried under a scope by its key.
      await tester.pumpWidget(_Host(builder: (context) => seeker));

      expect(
        tester.state<_SeekerState>(find.byType(_Seeker)),
        same(state),
        reason: 'the key kept the element, so this is a move and not a rebuild',
      );
      expect(state.found, isTrue);
      expect(state.dependencyChanges, 2);
    });
  });

  group('the child a scope was constructed with', () {
    // A scope builds what it shows through `buildChild()`. The `child` of the
    // constructor is there for a family that wants the plain `InheritedWidget`
    // behaviour and reads it itself; nothing in the package does, so the default
    // is a placeholder that refuses to become an element. It used to refuse with
    // a bare `UnimplementedError` raised from inside the framework, which is
    // immediate but says nothing.
    testWidgets('the placeholder nobody passed says which mistake it is',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _PlainChildScope(),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isA<UnimplementedError>());
      expect(
        exception.toString(),
        contains('buildChild()'),
        reason: 'the message names the way a scope is meant to build what it '
            'shows',
      );
    });

    testWidgets('a child that was passed is built', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _PlainChildScope(child: Text('passed in')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('passed in'), findsOneWidget);
    });
  });

  group('where a subscription may be taken', () {
    // What a dependent asked for is remembered per build, and the boundary
    // between one build and the next is taken from the frame. A registration
    // made outside a build therefore belongs to whichever build shares its
    // frame -- `didChangeDependencies` runs in the same frame as the build
    // that follows it, so the subscription looks like it works -- and is
    // dropped by the first build that does not share it, which is any rebuild
    // coming from the parent rather than from a change. Nothing could honour
    // it, so it is refused instead of quietly forgotten.
    testWidgets(
      'subscribing from didChangeDependencies is rejected',
      (tester) async {
        await tester.pumpWidget(
          _Host(builder: (context) => const _SubscribesTooEarly()),
        );

        expect(
          tester.takeException(),
          isA<AssertionError>().having(
            (error) => error.message.toString(),
            'message',
            contains('only be subscribed to from a build'),
          ),
        );
      },
      // The rejection is an assert raised from `didChangeDependencies`, so
      // the subtree it breaks stays unmounted -- see [unmountableTree].
      experimentalLeakTesting: unmountableTree,
    );

    // A `LayoutBuilder` runs its builder from `performLayout`, inside a
    // `BuildOwner.buildScope` of its own. That is a build in every sense this
    // rule is about -- what the builder returns is that element's subtree, and
    // the registration belongs to it -- but `debugDoingBuild` of a
    // `RenderObjectElement` is not raised for a layout callback, so the assert
    // refused a working and very common pattern. It worked in release all
    // along, which made this a difference between debug and release rather
    // than a rule.
    testWidgets('subscribing from a layout callback is allowed',
        (tester) async {
      var value = -1;

      await tester.pumpWidget(
        _Host(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              value = ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
                context,
                (element) => element.value,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(value, 0);

      (tester.element(find.byType(_Scope)) as _ScopeElement).bump();
      await tester.pump();

      expect(
        value,
        1,
        reason: 'and the subscription taken there is a real one, honoured by '
            'the next change like any other',
      );
    });

    // The same element runs its builder from two different places, and only
    // one of them has a layout in progress. `ListView.builder` builds its
    // items from `performLayout` on the first frame, and from its own
    // `performRebuild` -- in the build phase, with `debugActiveLayout` back to
    // null -- as soon as the parent hands it a new delegate. Neither of the
    // two raises `debugDoingBuild`, so the assert let the first one through
    // and refused the second: an item builder that reads the scope threw on
    // the first rebuild that came from the parent.
    testWidgets(
        'subscribing from an item builder survives a rebuild from the parent',
        (tester) async {
      var value = -1;

      Widget tree(String tag) => _Host(
            builder: (context) => ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                value = ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
                  context,
                  (element) => element.value,
                );

                return SizedBox(height: 40, child: Text(tag));
              },
            ),
          );

      await tester.pumpWidget(tree('first'));

      expect(tester.takeException(), isNull);
      expect(value, 0);

      await tester.pumpWidget(tree('second'));

      expect(
        tester.takeException(),
        isNull,
        reason: 'the items are rebuilt from the build phase this time, and '
            'that is the same registration as before',
      );

      (tester.element(find.byType(_Scope)) as _ScopeElement).bump();
      await tester.pump();

      expect(
        value,
        1,
        reason: 'and the subscription is a real one on both paths',
      );
    });

    // The mistake, made by a widget that is itself under a layout callback.
    // `debugActiveLayout` is raised for everything the callback builds and not
    // just for the builder itself, so letting layout callbacks in let this
    // through as well -- the price named in `doc/base.md` when it was done.
    // What tells the two apart is the dependent rather than the phase: the
    // framework is rebuilding it, and an element stays dirty until its own
    // build returns, while an element running a builder for somebody else has
    // been cleaned before the call.
    testWidgets(
      'subscribing from didChangeDependencies is rejected under a layout '
      'callback too',
      (tester) async {
        await tester.pumpWidget(
          _Host(
            builder: (context) => LayoutBuilder(
              builder: (context, constraints) => const _SubscribesTooEarly(),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isA<AssertionError>().having(
            (error) => error.message.toString(),
            'message',
            contains('only be subscribed to from a build'),
          ),
        );
      },
      // The rejection is an assert raised from `didChangeDependencies`, so
      // the subtree it breaks stays unmounted -- see [unmountableTree].
      experimentalLeakTesting: unmountableTree,
    );

    // A layout callback that reads the scope through the context of the widget
    // around it: the closure captures the enclosing `build`'s context instead
    // of its own, which is ordinary enough to write by accident and works.
    // The registration belongs to that outer element, which is not being
    // rebuilt while the callback runs, and the callback takes it again on
    // every layout.
    testWidgets('a layout callback may subscribe through the context above it',
        (tester) async {
      var value = -1;

      await tester.pumpWidget(
        _Host(
          builder: (outer) => LayoutBuilder(
            builder: (context, constraints) {
              value = ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
                outer,
                (element) => element.value,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(value, 0);

      (tester.element(find.byType(_Scope)) as _ScopeElement).bump();
      await tester.pump();

      expect(
        value,
        1,
        reason: 'and it is a real subscription, re-taken by the next layout',
      );
    });

    // The plainest form of the mistake: a context stashed from a builder and
    // subscribed to when nothing is being built at all. The builder context of
    // a lazy list is a `RenderObjectElement`, and that is let through only
    // while a build is in progress -- `BuildOwner.debugBuilding` is what says
    // it is.
    testWidgets('subscribing between frames is rejected whatever the context',
        (tester) async {
      late BuildContext stashed;

      await tester.pumpWidget(
        _Host(
          builder: (context) => ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              stashed = context;

              return const SizedBox(height: 40);
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        () => ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
          stashed,
          (element) => element.value,
        ),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message.toString(),
            'message',
            contains('only be subscribed to from a build'),
          ),
        ),
      );
    });
  });

  group('what a dependent subscribes to', () {
    testWidgets('a selector is the only thing that wakes a dependent up', (
      tester,
    ) async {
      var builds = 0;

      await tester.pumpWidget(
        _Host(
          builder: (context) {
            builds++;
            ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
              context,
              (element) => element.value,
            );

            return const SizedBox.shrink();
          },
        ),
      );
      final scope = tester.element(find.byType(_Scope)) as _ScopeElement;

      expect(builds, 1);

      scope.bumpOther();
      await tester.pump();
      expect(
        builds,
        1,
        reason: 'a change of a value nobody selected reaches nobody',
      );

      scope.bump();
      await tester.pump();
      expect(builds, 2, reason: 'the selected value did change');
    });

    testWidgets('listening to the scope subsumes any selector on it', (
      tester,
    ) async {
      var builds = 0;

      await tester.pumpWidget(
        _Host(
          builder: (context) {
            builds++;
            ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
              context,
              (element) => element.value,
            );
            ScopeWidgetCore.of<_Scope, _ScopeElement>(context, listen: true);

            return const SizedBox.shrink();
          },
        ),
      );
      final scope = tester.element(find.byType(_Scope)) as _ScopeElement;

      expect(builds, 1);

      scope.bumpOther();
      await tester.pump();
      expect(
        builds,
        2,
        reason: 'a subscription to everything cannot be narrowed by a selector',
      );
    });
  });

  // The invariant every dependency injection rests on, and the one thing the
  // suite had never put two scopes of one type in a tree to check. It is not
  // hypothetical either: `close()` reads the element it was made for rather
  // than looking one up precisely because a `wrapState` can nest a second
  // scope of the same type around the state.
  group('a scope shadowed by one of the same type', () {
    testWidgets('is not what a lookup from below finds', (tester) async {
      final seen = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Scope(
            label: 'outer',
            builder: (context) {
              seen.add(_labelOf(context));

              return _Scope(
                label: 'inner',
                builder: (context) {
                  seen.add(_labelOf(context));

                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      );

      expect(
        seen,
        ['outer', 'inner'],
        reason: 'each lookup answers the nearest scope above it, so the same '
            'call reads a different scope on either side of the inner one',
      );
    });

    testWidgets('does not wake the dependents of the one shadowing it',
        (tester) async {
      var builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Scope(
            label: 'outer',
            builder: (context) => _Scope(
              label: 'inner',
              builder: (context) {
                builds++;
                ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
                  context,
                  (element) => element.value,
                );

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final scopes = tester
          .elementList(find.byType(_Scope))
          .cast<_ScopeElement>()
          .toList();

      expect(builds, 1);

      scopes.first.bump();
      await tester.pump();

      expect(
        builds,
        1,
        reason: 'the value that changed belongs to the shadowed scope, which '
            'is not the one the dependent read',
      );

      scopes.last.bump();
      await tester.pump();

      expect(builds, 2, reason: 'the scope it did read is another matter');
    });
  });
}

/// The label of the nearest [_Scope] above [context].
String _labelOf(BuildContext context) =>
    ScopeWidgetCore.of<_Scope, _ScopeElement>(context, listen: false)
        .widget
        .label;

final class _Host extends StatelessWidget {
  final WidgetBuilder? builder;

  const _Host({this.builder});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: _Scope(builder: builder),
      );
}

/// Looks the scope up with `listen: true` and counts how often Flutter tells
/// it its dependencies changed.
final class _Seeker extends StatefulWidget {
  const _Seeker({super.key});

  @override
  State<_Seeker> createState() => _SeekerState();
}

final class _SeekerState extends State<_Seeker> {
  int dependencyChanges = 0;
  bool found = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dependencyChanges++;
  }

  @override
  Widget build(BuildContext context) {
    found = ScopeWidgetCore.maybeOf<_Scope, _ScopeElement>(
          context,
          listen: true,
        ) !=
        null;

    return const SizedBox.shrink();
  }
}

/// Subscribes from `didChangeDependencies`, which is a frame too early.
final class _SubscribesTooEarly extends StatefulWidget {
  const _SubscribesTooEarly();

  @override
  State<_SubscribesTooEarly> createState() => _SubscribesTooEarlyState();
}

final class _SubscribesTooEarlyState extends State<_SubscribesTooEarly> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
      context,
      (element) => element.value,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A family that builds the `child` it was constructed with, the plain
/// `InheritedWidget` way. By default that is the placeholder every
/// `ScopeInheritedWidget` carries.
final class _PlainChildScope
    extends ScopeWidgetCore<_PlainChildScope, _PlainChildScopeElement> {
  const _PlainChildScope({super.child});

  @override
  _PlainChildScopeElement createScopeElement() => _PlainChildScopeElement(this);
}

final class _PlainChildScopeElement
    extends ScopeWidgetElementBase<_PlainChildScope, _PlainChildScopeElement> {
  _PlainChildScopeElement(super.widget);

  @override
  Widget buildChild() => widget.child;
}

final class _Scope extends ScopeWidgetCore<_Scope, _ScopeElement> {
  final WidgetBuilder? builder;

  /// Tells one scope from another when a tree holds two of them.
  final String label;

  const _Scope({this.builder, this.label = ''});

  @override
  _ScopeElement createScopeElement() => _ScopeElement(this);
}

final class _ScopeElement
    extends ScopeWidgetElementBase<_Scope, _ScopeElement> {
  _ScopeElement(super.widget);

  int value = 0;
  int other = 0;
  int selfNotifications = 0;

  void bump() {
    value++;
    notifyDependents();
  }

  /// Changes a value nobody selects.
  void bumpOther() {
    other++;
    notifyDependents();
  }

  /// Whether [buildChild] subscribes the scope to a value of its own.
  ///
  /// From the build, because that is the only place a subscription can be
  /// taken -- see the assertion in `ScopeContext._find`. Called straight from
  /// a test it would be exactly the mistake that assertion is about.
  bool dependOnSelf = false;

  @override
  void didChangeDependencies() {
    selfNotifications++;
    super.didChangeDependencies();
  }

  @override
  Widget buildChild() {
    if (dependOnSelf) {
      ScopeWidgetCore.select<_Scope, _ScopeElement, int>(
        this,
        (element) => element.value,
      );
    }

    return Builder(
      builder: widget.builder ?? (_) => const SizedBox.shrink(),
    );
  }
}
