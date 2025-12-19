import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/common/presentation/animated_progress_indicator.dart';
import 'package:scopo_demo/common/presentation/counter.dart';

import '../../../../common/constants.dart';
import '../../../../common/presentation/box.dart';
import '../../../../common/presentation/consumer.dart';
import '../../../../common/presentation/expansion.dart';
import '../../../../common/presentation/markdown.dart';
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
        ValueListenableBuilder(
          valueListenable: _rebuildCounter,
          builder: (context, counter, child) {
            return Wrap(
              runSpacing: 8,
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                TitledBoxList(
                  title: const Text('Outside MyScope'),
                  titleBackgroundColor: Theme.of(context).colorScheme.secondary,
                  titleForegroundColor:
                      Theme.of(context).colorScheme.onSecondary,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        _restart(withError: false);
                      },
                      child: const Text('Restart'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
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
            );
          },
        ),
      ],
    );
  }
}

final class MyScopeDependencies implements ScopeDependencies {
  const MyScopeDependencies();

  @override
  FutureOr<void> dispose() {}
}

final class MyScope
    extends ScopeV2<MyScope, MyScopeDependencies, MyScopeState> {
  final int a;
  final int b;
  final bool withError;

  const MyScope({
    super.key,
    required this.a,
    required this.b,
    required this.withError,
  });

  @override
  Stream<ScopeProcessState<double, MyScopeDependencies>> init() async* {
    const count = 4;
    for (var i = 1; i <= count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (withError && i == count) {
        // ignore: only_throw_errors
        throw 'test error';
      }
      yield ScopeProgressV2(i / count);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));

    yield ScopeReadyV2(const MyScopeDependencies());
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
    return Center(
      child: SizedBox.square(
        dimension: 24,
        child: AnimatedProgressIndicator(
          value: progress as double?,
          builder: (value) {
            return CircularProgressIndicator(value: value);
          },
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
    return Center(
      child: Box(
        borderColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.error,
        child: Text(
          '$error${progress is double ? ': initialized at ${(progress * 100).toStringAsFixed(0)}%' : ''}',
        ),
      ),
    );
  }

  @override
  MyScopeState createState() => MyScopeState();

  static MyScope paramsOf(BuildContext context, {required bool listen}) =>
      ScopeV2.selectParam<MyScope, MyScopeDependencies, MyScopeState, MyScope>(
        context,
        (widget) => widget,
      );

  static V selectParam<V extends Object?>(
    BuildContext context,
    V Function(MyScope widget) selector,
  ) => ScopeV2.selectParam<MyScope, MyScopeDependencies, MyScopeState, V>(
    context,
    selector,
  );

  static MyScopeState of<
    W extends ScopeV2<W, D, S>,
    D extends ScopeDependencies,
    S extends ScopeState<W, D, S>
  >(BuildContext context) =>
      ScopeV2.of<MyScope, MyScopeDependencies, MyScopeState>(context);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(MyScopeState state) selector,
  ) => ScopeV2.select<MyScope, MyScopeDependencies, MyScopeState, V>(
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
            'a = selectParam(context, (w) => w.a)',
          ),
          builder: (context) {
            final a = MyScope.selectParam(context, (w) => w.a);
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
            'b = selectParam(context, (w) => w.b)',
          ),
          builder: (context) {
            final b = MyScope.selectParam(context, (w) => w.b);
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
      title: const Text('Initialized'),
      titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
      titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
      blinkingColor: Theme.of(context).colorScheme.tertiary,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Counter(title: 'MyScopeState.c', value: _c, increment: incrementC),
            Counter(title: 'MyScopeState.d', value: _d, increment: incrementD),
          ],
        ),
        const _ConsumerAInside(),
        const _ConsumerBInside(),
        const _ConsumerC(),
        const _ConsumerD(),
      ],
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
        'a = select(context, (s) => s.params.a)',
      ),
      builder: (context) {
        final a = MyScope.select(context, (s) => s.params.a);
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
        'b = select(context, (s) => s.params.b)',
      ),
      builder: (context) {
        final b = MyScope.select(context, (s) => s.params.b);
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
        'c = select(context, (s) => s.c)',
      ),
      builder: (context) {
        final c = MyScope.select(context, (s) => s.c);
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
        'd = select(context, (s) => s.d)',
      ),
      builder: (context) {
        final d = MyScope.select(context, (s) => s.d);
        return Text('d: $d');
      },
    );
  }
}
