import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/presentation/blinking_box.dart';
import '../../../../../../common/presentation/titled_box.dart';

final class Model with ChangeNotifier {
  var _counter = 0;
  int get counter => _counter;

  void increment() {
    _counter++;
    notifyListeners();
  }
}

class ModelScope extends StatelessWidget {
  const ModelScope({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeNotifier<Model>(
      create: (context) => Model(),
      dispose: (model) => model.dispose(),
      // With `ScopeNotifier`, content can be either constant
      // or non-constant.
      builder: (context) {
        return Center(
          child: TitledBox(
            title: const Text('Result'),
            blinkingColor: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                // We use `Builder` so that changes in `ScopeNotifier`
                // do not affect other widgets.
                Builder(
                  builder: (context) {
                    final counter = ScopeNotifier.select<Model, int>(
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
                    ScopeNotifier.of<Model>(context, listen: false).increment();
                  },
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
