import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../common/presentation/blinking_box.dart';
import '../../../utils/console/console.dart';

final class CounterModel with ChangeNotifier {
  final Object debugSource;
  final String debugName;

  CounterModel({
    required this.debugSource,
    required this.debugName,
  });

  int? _count;
  int get count =>
      _count ?? (throw Exception('$CounterModel is not initialized'));

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

final class CounterScope extends AsyncScopeBase<CounterScope, CounterModel> {
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
  });

  static CounterModel of(BuildContext context) =>
      AsyncScopeBase.of<CounterScope, CounterModel>(
        context,
        listen: false,
      ).data;

  static int countOf(BuildContext context) =>
      AsyncScopeBase.select<CounterScope, CounterModel, int>(
        context,
        (context) => context.data.count,
      );

  @override
  Future<CounterModel> asyncInit(BuildContext context) async {
    final model = CounterModel(
      debugSource: debugSource,
      debugName: debugName,
    );
    await model.init();
    return model;
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
  Widget buildOnInitializing(BuildContext context) {
    return const Text('Initializing...');
  }

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    return Text('Error: $error');
  }

  @override
  Widget buildOnReady(BuildContext context, CounterModel value) {
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
