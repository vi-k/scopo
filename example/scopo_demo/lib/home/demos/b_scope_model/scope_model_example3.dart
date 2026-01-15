import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

class ScopeModelExample3 extends StatelessWidget {
  const ScopeModelExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CounterScope());
  }
}

class CounterScope extends StatefulWidget {
  const CounterScope({super.key});

  static CounterScopeState of(BuildContext context) =>
      ScopeModel.of<CounterScopeState>(context, listen: false);

  static V select<V>(
    BuildContext context,
    V Function(CounterScopeState state) selector,
  ) => ScopeModel.select<CounterScopeState, V>(context, selector);

  @override
  State<CounterScope> createState() => CounterScopeState();
}

class CounterScopeState extends State<CounterScope> {
  int _count = 0;
  int get count => _count;

  void increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopeModel.value(
      value: this,
      builder:
          (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$ScopeModelExample3'),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_CounterView(), _IncrementAction()],
              ),
            ],
          ),
    );
  }
}

class _CounterView extends StatelessWidget {
  const _CounterView();

  @override
  Widget build(BuildContext context) {
    final count = CounterScope.select<int>(context, (state) => state.count);
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
