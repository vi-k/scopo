import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

class ScopeModelExample2 extends StatelessWidget {
  const ScopeModelExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CounterScope());
  }
}

final class CounterModel {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
  }
}

final class CounterScope
    extends ScopeModelCore<CounterScope, CounterScopeElement, CounterModel> {
  const CounterScope({super.key});

  static CounterScopeContext of(BuildContext context) =>
      ScopeModelCore.of<CounterScope, CounterScopeElement, CounterModel>(
        context,
        listen: false,
      );

  static int countOf(BuildContext context) => ScopeModelCore.select<
    CounterScope,
    CounterScopeElement,
    CounterModel,
    int
  >(context, (element) => element.model.count);

  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_CounterView(), _IncrementAction()],
    );
  }

  @override
  CounterScopeElement createScopeElement() => CounterScopeElement(this);
}

abstract interface class CounterScopeContext {
  CounterModel get model;
  void increment();
}

final class CounterScopeElement
    extends
        ScopeModelElementBase<CounterScope, CounterScopeElement, CounterModel>
    implements CounterScopeContext {
  CounterScopeElement(super.widget);

  @override
  final CounterModel model = CounterModel();

  @override
  Widget buildChild() => widget.build(this);

  @override
  void increment() {
    model.increment();
    notifyDependents();
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
