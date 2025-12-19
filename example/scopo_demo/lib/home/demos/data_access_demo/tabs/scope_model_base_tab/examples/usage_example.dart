import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/presentation/blinking_box.dart';
import '../../../../../../common/presentation/markdown.dart';
import '../../../../../../common/presentation/titled_box.dart';
import '../../../../../../common/utils/string_extensions.dart';

final class Model with ChangeNotifier {
  var _modelCounter = 0;
  int get modelCounter => _modelCounter;

  void increment() {
    _modelCounter++;
    notifyListeners();
  }
}

final class ModelScope extends ScopeNotifierBase<ModelScope, Model> {
  final Widget Function(BuildContext context) builder;
  final int configCounter;

  const ModelScope({
    super.key,
    required this.configCounter,
    required super.create,
    required super.dispose,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }

  static ScopeModelContext<ModelScope, Model> get(BuildContext context) =>
      ScopeNotifierBase.of<ModelScope, Model>(context, listen: false);

  static ScopeModelContext<ModelScope, Model> depend(BuildContext context) =>
      ScopeNotifierBase.of<ModelScope, Model>(context, listen: true);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(ScopeModelContext<ModelScope, Model> e) selector,
  ) => ScopeNotifierBase.select<ModelScope, Model, V>(context, selector);
}

class Usage extends StatefulWidget {
  const Usage({super.key});

  @override
  State<Usage> createState() => _UsageState();
}

class _UsageState extends State<Usage> {
  var _counter = 0;
  int get counter => _counter;

  void increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModelScope(
      configCounter: _counter,
      create: (context) => Model(),
      dispose: (model) => model.dispose(),
      builder: (context) {
        return Center(
          child: TitledBox(
            title: const Text('Result'),
            blinkingColor: Theme.of(context).colorScheme.primary,
            child: Column(
              children: [
                Markdown(
                  '''
                  `configCounter` is only updated via the parent's `setState`
                  '''.trimIndent(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // We use `Builder` so that changes in `ModelScope`
                    // do not affect other widgets.
                    Builder(
                      builder: (context) {
                        final modelCounter = ModelScope.select<int>(
                          context,
                          (context) => context.model.modelCounter,
                        );

                        return BlinkingBox(
                          blinkingColor: Theme.of(context).colorScheme.primary,
                          child: Text('modelCounter: $modelCounter'),
                        );
                      },
                    ),
                    IconButton(
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        ModelScope.get(context).model.increment();
                      },
                      icon: const Icon(Icons.add_circle),
                    ),
                    Builder(
                      builder: (context) {
                        final configCounter = ModelScope.select<int>(
                          context,
                          (context) => context.widget.configCounter,
                        );

                        return BlinkingBox(
                          blinkingColor: Theme.of(context).colorScheme.primary,
                          child: Text('configCounter: $configCounter'),
                        );
                      },
                    ),
                    IconButton(
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: increment,
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    return Text('i=${++i}');
  }
}
