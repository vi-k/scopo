import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

class ScopeNotifierExample1 extends StatelessWidget {
  const ScopeNotifierExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: CounterScope());
  }
}

final class CounterModel with ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

final class CounterScope extends ScopeNotifierBase<CounterScope, CounterModel> {
  CounterScope({super.key})
    : super(create: (_) => CounterModel(), dispose: (model) => model.dispose());

  static CounterModel of(BuildContext context) =>
      ScopeNotifierBase.of<CounterScope, CounterModel>(
        context,
        listen: false,
      ).model;

  static int countOf(BuildContext context) =>
      ScopeNotifierBase.select<CounterScope, CounterModel, int>(
        context,
        (context) => context.model.count,
      );

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_CounterView(), _IncrementAction()],
    );
  }
}

class _CounterView extends StatelessWidget {
  const _CounterView();

  @override
  Widget build(BuildContext context) {
    final count = CounterScope.countOf(context);
    return Center(child: Text('$count'));
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
