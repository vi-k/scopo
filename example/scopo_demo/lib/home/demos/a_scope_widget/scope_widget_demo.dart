import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../common/presentation/titled_box.dart';

class ScopeWidgetDemo extends StatefulWidget {
  const ScopeWidgetDemo({super.key});

  @override
  State<ScopeWidgetDemo> createState() => _ScopeWidgetDemoState();
}

class _ScopeWidgetDemoState extends State<ScopeWidgetDemo> {
  var _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        CounterScopeWidget(count: _count),
        FilledButton(onPressed: _increment, child: const Text('increment')),
      ],
    );
  }
}

final class CounterScopeWidget extends ScopeWidgetBase<CounterScopeWidget> {
  final int count;

  const CounterScopeWidget({super.key, required this.count});

  static int countOf(BuildContext context) =>
      ScopeWidgetBase.select<CounterScopeWidget, int>(
        context,
        (widget) => widget.count,
      );

  @override
  Widget build(BuildContext context) {
    return TitledBox(
      title: Text('$CounterScopeWidget'),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final count = CounterScopeWidget.countOf(context);

    return Center(child: Text('$count'));
  }
}
