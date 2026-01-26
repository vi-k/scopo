import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../common/presentation/blinking_box.dart';
import '../../../utils/console/console.dart';

final class CounterModel with ChangeNotifier {
  static const int steps = 10;

  final Object debugSource;
  final String debugName;

  CounterModel._({
    required this.debugSource,
    required this.debugName,
  });

  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  static Stream<ScopeInitState<int, CounterModel>> init({
    required Object debugSource,
    required String debugName,
  }) async* {
    console.log(debugSource, '$debugName: initialize');

    var isInitialized = false;

    try {
      for (var i = 0; i <= steps; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        yield ScopeProgress(i);
      }

      yield ScopeReady(
        CounterModel._(
          debugSource: debugSource,
          debugName: debugName,
        ),
      );

      isInitialized = true;
      console.log(debugSource, '$debugName: initialized');
    } finally {
      if (!isInitialized) {
        console.log(debugSource, '$debugName: cancelled');
      }
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();

    await null;
    console.log(debugSource, '$debugName: dispose');

    await Future<void>.delayed(const Duration(seconds: 2));

    console.log(debugSource, '$debugName: disposed');
  }
}

final class CounterScope extends StreamScopeBase<CounterScope, CounterModel> {
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

  static CounterModel of(BuildContext context) =>
      StreamScopeBase.of<CounterScope, CounterModel>(
        context,
        listen: false,
      ).data;

  static int countOf(BuildContext context) =>
      StreamScopeBase.select<CounterScope, CounterModel, int>(
        context,
        (context) => context.data.count,
      );

  @override
  Stream<ScopeInitState<int, CounterModel>> asyncInit(BuildContext context) {
    return CounterModel.init(debugSource: debugSource, debugName: debugName);
  }

  @override
  Future<void> asyncDispose(CounterModel data) async {
    await data.dispose();
  }

  @override
  Widget Function(BuildContext context) get buildOnWaitingForPrevious =>
      (context) {
        return const Text('Waiting for the previous one to be disposed of...');
      };

  @override
  Widget buildOnInitializing(BuildContext context, covariant int? progress) {
    return Text(
      'Initializing${progress == null ? '' : ' ($progress/${CounterModel.steps})'}',
    );
  }

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    covariant int? progress,
  ) {
    return Text(
      'Error${progress == null ? '' : ' on step $progress'}: $error',
    );
  }

  @override
  Widget buildOnReady(BuildContext context, CounterModel data) {
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

    if (childScope case final child?) {
      body = Row(
        children: [
          Expanded(child: body),
          const VerticalDivider(),
          Expanded(child: child),
        ],
      );
    }

    if (title case final title?) {
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
    return ListenableSelector<CounterModel, int>(
      listenable: CounterScope.of(context),
      selector: (model) => model.count,
      builder: (context, model, count, _) {
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
      onPressed: CounterScope.of(context).increment,
      icon: const Icon(Icons.add_circle),
    );
  }
}
