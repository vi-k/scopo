import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/common/presentation/blinking_box.dart';

import '../../../../common/presentation/box.dart';

class ModelScope extends StatefulWidget {
  const ModelScope({super.key});

  @override
  State<ModelScope> createState() => ModelScopeState();
}

class ModelScopeState extends State<ModelScope> {
  var _counter = 0;
  int get counter => _counter;

  void increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<ModelScopeState>.value(
      value: this,
      // If you remove `const`, the logic will
      // change significantly!
      builder: (context) => const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Box(
        title: Text('Result'),
        blinkingColor: Theme.of(context).colorScheme.primary,
        child: Row(
          children: [
            // We use `Builder` so that changes in `ScopeProvider`
            // do not affect other widgets.
            Builder(
              builder: (context) {
                final counter = ScopeProvider.select<ModelScopeState, int>(
                    context, (m) => m.counter);
                return BlinkingBox(
                  blinkingColor: Theme.of(context).colorScheme.primary,
                  child: Text('$counter'),
                );
              },
            ),
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                ScopeProvider.get<ModelScopeState>(context).increment();
              },
              icon: const Icon(Icons.add_circle),
            ),
          ],
        ),
      ),
    );
  }
}
