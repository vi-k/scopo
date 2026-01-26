import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../common/presentation/blinking_box.dart';
import '../../../utils/console/console.dart';

final class CounterController with ChangeNotifier {
  final Object debugSource;
  final String debugName;

  CounterController({
    required this.debugSource,
    required this.debugName,
  });

  int? _count;
  int get count => _count ?? (throw StateError('Not initialized'));

  void increment() {
    _count = count + 1;
    notifyListeners();
  }

  Future<void> init() async {
    console.log(debugSource, '$debugName: initialize');

    await Future<void>.delayed(const Duration(seconds: 2));
    _count = 0;

    console.log(debugSource, '$debugName: initialized');
  }

  @override
  Future<void> dispose() async {
    super.dispose();

    console.log(debugSource, '$debugName: dispose');

    await Future<void>.delayed(const Duration(seconds: 1));
    _count = null;

    console.log(debugSource, '$debugName: disposed');
  }
}

final class CounterDependencies extends ScopeDependencies
    with ScopeQueueMixin<CounterDependencies> {
  final Object debugSource;
  final String debugName;

  late final CounterController counterController;

  CounterDependencies({
    required this.debugSource,
    required this.debugName,
  });

  @override
  List<List<ScopeDependencyBase>> buildQueue(BuildContext context) => [
        [
          ScopeDependency(
            'counterController',
            () async {
              counterController = CounterController(
                debugSource: debugSource,
                debugName: debugName,
              );
              await counterController.init();
            },
            onDispose: () async {
              await counterController.dispose();
            },
          ),
          ScopeDependency(
            'test 1',
            () async {
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
          ),
        ],
        [
          ScopeDependency(
            'test 2',
            () async {
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
          ),
        ],
      ];
}

final class CounterScope
    extends Scope<CounterScope, CounterDependencies, CounterState> {
  final String? title;
  final Widget? childScope;
  final Object debugSource;
  final String debugName;

  const CounterScope({
    super.key,
    super.scopeKey,
    this.title,
    this.childScope,
    required this.debugSource,
    required this.debugName,
  }) : super(pauseAfterInitialization: const Duration(milliseconds: 1000));

  static CounterScope paramsOf(BuildContext context) =>
      Scope.paramsOf<CounterScope, CounterDependencies, CounterState>(
        context,
        listen: false,
      );

  static V selectParam<V>(
    BuildContext context,
    V Function(CounterScope widget) selector,
  ) =>
      Scope.selectParam<CounterScope, CounterDependencies, CounterState, V>(
        context,
        selector,
      );

  static CounterState of(BuildContext context) =>
      Scope.of<CounterScope, CounterDependencies, CounterState>(context);

  static String? titleOf(BuildContext context) => Scope.selectParam<
          CounterScope, CounterDependencies, CounterState, String?>(
        context,
        (widget) => widget.title,
      );

  static Widget? childOf(BuildContext context) => Scope.selectParam<
          CounterScope, CounterDependencies, CounterState, Widget?>(
        context,
        (widget) => widget.childScope,
      );

  @override
  Stream<ScopeInitState<ScopeQueueProgress, CounterDependencies>>
      initDependencies(
    BuildContext context,
  ) =>
          CounterDependencies(
            debugSource: debugSource,
            debugName: debugName,
          ).init(context);

  @override
  Widget Function(BuildContext context) get buildOnWaitingForPrevious =>
      (context) {
        return const Text('Waiting for the previous one to be disposed of...');
      };

  @override
  Widget buildOnInitializing(
    BuildContext context,
    covariant ScopeQueueProgress? progress,
  ) {
    return Text(
      'Initializing'
      '${progress == null ? '' : ' ${progress.number}/${progress.total}'}',
    );
  }

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    covariant ScopeQueueProgress? progress,
  ) {
    return Text(
      'Error${progress == null ? '' : ' on step $progress'}: $error',
    );
  }

  @override
  CounterState createState() => CounterState();
}

final class CounterState
    extends ScopeState<CounterScope, CounterDependencies, CounterState> {
  late final Object _debugSource;
  late final String _debugName;

  @override
  Future<void> asyncInit() async {
    _debugSource = CounterScope.paramsOf(context).debugSource;
    _debugName = CounterScope.paramsOf(context).debugName;

    console.log(_debugSource, '$_debugName: state initialize');

    await Future<void>.delayed(const Duration(seconds: 2));

    console.log(_debugSource, '$_debugName: state initialized');
  }

  @override
  Future<void> asyncDispose() async {
    console.log(_debugSource, '$_debugName: state dispose');

    await Future<void>.delayed(const Duration(seconds: 1));

    console.log(_debugSource, '$_debugName: state disposed');
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Center(
      child: BlinkingBox(
        blinkingColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [_CounterView(), _IncrementAction()],
            ),
          ],
        ),
      ),
    );

    if (CounterScope.childOf(context) case final child?) {
      final mainContent = body;
      body = FutureBuilder(
        future: whenIsInitialized,
        builder: (context, snapshot) {
          return snapshot.connectionState != ConnectionState.done
              ? mainContent
              : Row(
                  children: [
                    Expanded(child: mainContent),
                    const VerticalDivider(),
                    Expanded(child: child),
                  ],
                );
        },
      );
    }

    if (CounterScope.titleOf(context) case final title?) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          body,
        ],
      );
    }

    return body;
  }
}

class _CounterView extends StatelessWidget {
  const _CounterView();

  @override
  Widget build(BuildContext context) {
    return ListenableSelector<CounterController, int>(
      listenable: CounterScope.of(context).dependencies.counterController,
      selector: (controller) => controller.count,
      builder: (context, controller, count, _) {
        return Center(
          child: BlinkingBox(
            blinkingColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Text('$count'),
          ),
        );
      },
    );
  }
}

class _IncrementAction extends StatelessWidget {
  const _IncrementAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: Theme.of(context).colorScheme.primary,
      onPressed:
          CounterScope.of(context).dependencies.counterController.increment,
      icon: const Icon(Icons.add_circle),
    );
  }
}
