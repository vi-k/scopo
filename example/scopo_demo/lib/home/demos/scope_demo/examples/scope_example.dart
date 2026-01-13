import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/common/presentation/animated_progress_indicator.dart';
import 'package:scopo_demo/common/presentation/counter.dart';

import '../../../../common/constants.dart';
import '../../../../common/presentation/consumer.dart';
import '../../../../common/presentation/expansion.dart';
import '../../../../common/presentation/markdown.dart';
import '../../../../common/presentation/titled_box.dart';
import '../../../../common/presentation/titled_box_list.dart';

class ScopeExample extends StatefulWidget {
  const ScopeExample({super.key});

  @override
  State<ScopeExample> createState() => _ScopeExampleState();
}

class _ScopeExampleState extends State<ScopeExample> {
  final _rebuildCounter = ValueNotifier<int>(0);
  final _scopeA = ValueNotifier<int>(0);
  final _scopeB = ValueNotifier<int>(0);
  var _withError = false;

  void _restart({required bool withError}) {
    _withError = withError;
    _rebuildCounter.value++;
  }

  void incrementA() {
    _scopeA.value++;
  }

  void incrementB() {
    _scopeB.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Expansion(
      initiallyExpanded: true,
      title: const Markdown(Constants.exampleTitle, selectable: false),
      children: [
        Wrap(
          runSpacing: 8,
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            TitledBoxList(
              title: const Text('Outside MyScope'),
              titleBackgroundColor: Theme.of(context).colorScheme.secondary,
              titleForegroundColor: Theme.of(context).colorScheme.onSecondary,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: () {
                    _restart(withError: false);
                  },
                  child: const Text('Restart'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: () {
                    _restart(withError: true);
                  },
                  child: const Text('Restart with error'),
                ),
                ValueListenableBuilder(
                  valueListenable: _scopeA,
                  builder: (context, value, child) {
                    return Counter(
                      title: 'MyScope.a',
                      value: value,
                      increment: incrementA,
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _scopeB,
                  builder: (context, value, child) {
                    return Counter(
                      title: 'MyScope.b',
                      value: value,
                      increment: incrementB,
                    );
                  },
                ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: _rebuildCounter,
              builder: (context, rebuildCounter, child) {
                return ValueListenableBuilder(
                  valueListenable: _scopeA,
                  builder: (context, a, child) {
                    return ValueListenableBuilder(
                      valueListenable: _scopeB,
                      builder: (context, b, child) {
                        return MyScope(
                          key: ValueKey(_rebuildCounter.value),
                          a: a,
                          b: b,
                          withError: _withError,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

final class MyScopeDependencies implements ScopeDependencies {
  const MyScopeDependencies();

  @override
  FutureOr<void> dispose() async {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

final class MyScope extends Scope<MyScope, MyScopeDependencies, MyScopeState> {
  final int a;
  final int b;
  final bool withError;

  const MyScope({
    super.key,
    required this.a,
    required this.b,
    required this.withError,
  }) : super(exclusiveCoordinatorKey: const ValueKey('my_scope'));

  @override
  Stream<ScopeInitState<double, MyScopeDependencies>> init() async* {
    const count = 4;
    for (var i = 1; i <= count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (withError && i == count) {
        // ignore: only_throw_errors
        throw 'test error';
      }
      yield ScopeProgress(i / count);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));

    yield ScopeReady(const MyScopeDependencies());
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return TitledBoxList(
      title: const Text('MyScope'),
      titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
      titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
      children: [const _ConsumerAOutside(), const _ConsumerBOutside(), child],
    );
  }

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) {
    return TitledBox(
      title: const Text('buildOnInitializing'),
      titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
      titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: AnimatedProgressIndicator(
            value: progress as double?,
            builder: (value) {
              return CircularProgressIndicator(value: value);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) {
    return TitledBox(
      title: const Text('buildOnError'),
      titleBackgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.error,
      child: Center(
        child: Text('$error${progress == null ? '' : ' on $progress'}'),
      ),
    );
  }

  @override
  MyScopeState createState() => MyScopeState();

  static MyScope paramsOf(BuildContext context, {required bool listen}) =>
      Scope.selectParam<MyScope, MyScopeDependencies, MyScopeState, MyScope>(
        context,
        (widget) => widget,
      );

  static V selectParam<V extends Object?>(
    BuildContext context,
    V Function(MyScope widget) selector,
  ) => Scope.selectParam<MyScope, MyScopeDependencies, MyScopeState, V>(
    context,
    selector,
  );

  static MyScopeState of(BuildContext context) =>
      Scope.of<MyScope, MyScopeDependencies, MyScopeState>(context);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(MyScopeState state) selector,
  ) => Scope.select<MyScope, MyScopeDependencies, MyScopeState, V>(
    context,
    selector,
  );
}

class _ConsumerAOutside extends StatelessWidget {
  const _ConsumerAOutside();

  @override
  Widget build(BuildContext context) {
    return TitledBoxList(
      title: const Text('dependent on [MyScope.a]'),
      titleBackgroundColor: Theme.of(context).colorScheme.primary,
      titleForegroundColor: Theme.of(context).colorScheme.onPrimary,
      blinkingColor: Theme.of(context).colorScheme.primary,
      children: [
        Consumer(
          blinkingColor: Theme.of(context).colorScheme.primary,
          description: const Markdown(
            fontSize: 12,
            'a = paramsOf(context, listen: true).a',
          ),
          builder: (context) {
            final a = MyScope.paramsOf(context, listen: true).a;
            return Text('a: $a');
          },
        ),
        Consumer(
          blinkingColor: Theme.of(context).colorScheme.primary,
          description: const Markdown(
            fontSize: 12,
            'a = selectParam(context, (widget) => widget.a)',
          ),
          builder: (context) {
            final a = MyScope.selectParam(context, (widget) => widget.a);
            return Text('a: $a');
          },
        ),
      ],
    );
  }
}

class _ConsumerBOutside extends StatelessWidget {
  const _ConsumerBOutside();

  @override
  Widget build(BuildContext context) {
    return TitledBoxList(
      title: const Text('dependent on [MyScope.b]'),
      titleBackgroundColor: Theme.of(context).colorScheme.primary,
      titleForegroundColor: Theme.of(context).colorScheme.onPrimary,
      blinkingColor: Theme.of(context).colorScheme.primary,
      children: [
        Consumer(
          blinkingColor: Theme.of(context).colorScheme.primary,
          description: const Markdown(
            fontSize: 12,
            'b = paramsOf(context, listen: true).b',
          ),
          builder: (context) {
            final b = MyScope.paramsOf(context, listen: true).b;
            return Text('b: $b');
          },
        ),
        Consumer(
          blinkingColor: Theme.of(context).colorScheme.primary,
          description: const Markdown(
            fontSize: 12,
            'b = selectParam(context, (widget) => widget.b)',
          ),
          builder: (context) {
            final b = MyScope.selectParam(context, (widget) => widget.b);
            return Text('b: $b');
          },
        ),
      ],
    );
  }
}

final class MyScopeState
    extends ScopeState<MyScope, MyScopeDependencies, MyScopeState> {
  var _c = 0;
  int get c => _c;

  var _d = 0;
  int get d => _d;

  void incrementC() {
    _c++;
    notifyDependents();
  }

  void incrementD() {
    _d++;
    notifyDependents();
  }

  @override
  Widget build(BuildContext context) {
    return TitledBoxList(
      title: const Text('buildOnInitialized'),
      titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
      titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
      // for testing
      // blinkingColor: Theme.of(context).colorScheme.tertiary,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_CounterC(), _CounterD()],
        ),
        _ConsumerAInside(),
        _ConsumerBInside(),
        _ConsumerC(),
        _ConsumerD(),
      ],
    );
  }
}

class _CounterC extends StatelessWidget {
  const _CounterC();

  @override
  Widget build(BuildContext context) {
    return Counter(
      title: 'MyScopeState.c',
      value: MyScope.select(context, (state) => state.c),
      increment: MyScope.of(context).incrementC,
    );
  }
}

class _CounterD extends StatelessWidget {
  const _CounterD();

  @override
  Widget build(BuildContext context) {
    return Counter(
      title: 'MyScopeState.d',
      value: MyScope.select(context, (state) => state.d),
      increment: MyScope.of(context).incrementD,
    );
  }
}

class _ConsumerAInside extends StatelessWidget {
  const _ConsumerAInside();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      title: const Text('dependent on [MyScope.a]'),
      blinkingColor: Theme.of(context).colorScheme.primary,
      description: const Markdown(
        fontSize: 12,
        'a = select(context, (state) => state.params.a)',
      ),
      builder: (context) {
        final a = MyScope.select(context, (state) => state.params.a);
        return Text('a: $a');
      },
    );
  }
}

class _ConsumerBInside extends StatelessWidget {
  const _ConsumerBInside();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      title: const Text('dependent on [MyScope.b]'),
      blinkingColor: Theme.of(context).colorScheme.primary,
      description: const Markdown(
        fontSize: 12,
        'b = select(context, (state) => state.params.b)',
      ),
      builder: (context) {
        final b = MyScope.select(context, (state) => state.params.b);
        return Text('b: $b');
      },
    );
  }
}

class _ConsumerC extends StatelessWidget {
  const _ConsumerC();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      title: const Text('dependent on [MyScopeState.c]'),
      blinkingColor: Theme.of(context).colorScheme.primary,
      description: const Markdown(
        fontSize: 12,
        'c = select(context, (state) => state.c)',
      ),
      builder: (context) {
        final c = MyScope.select(context, (state) => state.c);
        return Text('c: $c');
      },
    );
  }
}

class _ConsumerD extends StatelessWidget {
  const _ConsumerD();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      title: const Text('dependent on [MyScopeState.d]'),
      blinkingColor: Theme.of(context).colorScheme.primary,
      description: const Markdown(
        fontSize: 12,
        'd = select(context, (state) => state.d)',
      ),
      builder: (context) {
        final d = MyScope.select(context, (state) => state.d);
        return Text('d: $d');
      },
    );
  }
}
