import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../common/presentation/titled_box.dart';

final class CounterModel {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
  }
}

class ScopeModelDemo extends StatefulWidget {
  const ScopeModelDemo({super.key});

  @override
  State<ScopeModelDemo> createState() => _ScopeModelDemoState();
}

class _ScopeModelDemoState extends State<ScopeModelDemo> {
  final _model = CounterModel();

  void _increment() {
    setState(_model.increment);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        CounterScopeModel(model: _model),
        FilledButton(onPressed: _increment, child: const Text('increment')),
      ],
    );
  }
}

final class CounterScopeModel
    extends ScopeModelBase<CounterScopeModel, CounterModel> {
  const CounterScopeModel({super.key, required CounterModel model})
    : super.value(value: model);

  static int countOf(BuildContext context) =>
      ScopeModelBase.select<CounterScopeModel, CounterModel, int>(
        context,
        (context) => context.model.count,
      );

  @override
  Widget build(BuildContext context) {
    return TitledBox(
      title: Text('$CounterScopeModel'),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final count = CounterScopeModel.countOf(context);

    return Center(child: Text('$count'));
  }
}
