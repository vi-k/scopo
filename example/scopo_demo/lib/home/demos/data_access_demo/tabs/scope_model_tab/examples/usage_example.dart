import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/presentation/blinking_box.dart';
import '../../../../../../common/presentation/titled_box.dart';

class CounterScope extends StatefulWidget {
  const CounterScope({super.key});

  // To obtain data, you can use the
  // `ScopeModel.of<CounterScopeState>` and
  // `ScopeModel.select<CounterScopeState>` methods
  // directly, but when working with a scope, its own
  // methods `CounterScope.of` and `CounterScope.select`
  // are preferable.

  static CounterScopeState of(BuildContext context) =>
      ScopeModel.of<CounterScopeState>(context, listen: false);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(CounterScopeState) selector,
  ) => ScopeModel.select<CounterScopeState, V>(context, selector);

  @override
  State<CounterScope> createState() => CounterScopeState();
}

class CounterScopeState extends State<CounterScope> {
  var _counter = 0;
  int get counter => _counter;

  void increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopeModel<CounterScopeState>.value(
      value: this,
      // You can set your own `ScopeModel` name to be
      // displayed in the Inspector.
      debugName: '${CounterScope}Model',
      // To keep `_Content` constant, do not pass parameters
      // through the `_Content` constructor. Access them
      // using `CounterScope.of` and `CounterScope.select`.
      builder: (context) {
        return const _Content();
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TitledBox(
        title: const Text('Result'),
        blinkingColor: Theme.of(context).colorScheme.primary,
        child: Row(
          children: [
            // We use `Builder` so that changes in
            // `ScopeModel` do not affect other widgets.
            Builder(
              builder: (context) {
                final counter = CounterScope.select<int>(
                  context,
                  (m) => m.counter,
                );
                return BlinkingBox(
                  blinkingColor: Theme.of(context).colorScheme.primary,
                  child: Text('$counter'),
                );
              },
            ),
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                CounterScope.of(context).increment();
              },
              icon: const Icon(Icons.add_circle),
            ),
          ],
        ),
      ),
    );
  }
}
