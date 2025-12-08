import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../common/presentation/blinking_box.dart';
import '../../../../common/presentation/box.dart';

final class Model with ChangeNotifier {
  var _modelCounter = 0;
  int get modelCounter => _modelCounter;

  void increment() {
    _modelCounter++;
    notifyListeners();
  }
}

final class ModelScope extends ScopeNotifierBase<ModelScope, Model> {
  final int configCounter;

  const ModelScope({
    super.key,
    required this.configCounter,
    required super.create,
    required super.builder,
  });

  static ScopeProviderFacade<ModelScope, Model> get(
    BuildContext context,
  ) =>
      ScopeNotifierBase.get<ModelScope, Model>(context);

  static ScopeProviderFacade<ModelScope, Model> depend(
    BuildContext context,
  ) =>
      ScopeNotifierBase.depend<ModelScope, Model>(context);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(ScopeProviderFacade<ModelScope, Model> e) selector,
  ) =>
      ScopeNotifierBase.select<ModelScope, Model, V>(context, selector);
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
      builder: (context) => Center(
        child: Box(
          title: Text('Result'),
          blinkingColor: Theme.of(context).colorScheme.primary,
          child: Row(
            children: [
              // We use `Builder` so that changes in `ModelScope`
              // do not affect other widgets.
              Builder(
                builder: (context) {
                  final modelCounter = ModelScope.select<int>(
                      context, (f) => f.model.modelCounter);

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
                      context, (f) => f.widget.configCounter);

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
        ),
      ),
    );
  }
}
