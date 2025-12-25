import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../common/presentation/titled_box.dart';

final class CounterModel with ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

class ScopeNotifierDemo extends StatelessWidget {
  const ScopeNotifierDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [CounterScopeNotifier()],
    );
  }
}

final class CounterScopeNotifier
    extends ScopeNotifierBase<CounterScopeNotifier, CounterModel> {
  CounterScopeNotifier({super.key})
    : super(create: (_) => CounterModel(), dispose: (model) => model.dispose());

  static CounterModel of(BuildContext context) =>
      ScopeNotifierBase.of<CounterScopeNotifier, CounterModel>(
        context,
        listen: false,
      ).model;

  static int countOf(BuildContext context) =>
      ScopeNotifierBase.select<CounterScopeNotifier, CounterModel, int>(
        context,
        (context) => context.model.count,
      );

  @override
  Widget build(BuildContext context) {
    return TitledBox(
      title: Text('$CounterScopeNotifier'),
      child: const Column(spacing: 8, children: [_Count(), _IncrementAction()]),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count();

  @override
  Widget build(BuildContext context) {
    final count = CounterScopeNotifier.countOf(context);

    return Center(child: Text('$count'));
  }
}

class _IncrementAction extends StatelessWidget {
  const _IncrementAction();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: CounterScopeNotifier.of(context).increment,
      child: const Text('increment'),
    );
  }
}
