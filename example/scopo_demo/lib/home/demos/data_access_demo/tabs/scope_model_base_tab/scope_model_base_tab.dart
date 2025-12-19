import 'package:flutter/material.dart';

import '../../../../../common/presentation/code.dart';
import '../../../../../common/presentation/expansion.dart';
import '../../../../../common/presentation/markdown.dart';
import '../../../../../common/utils/string_extensions.dart';
import 'examples/usage_example.dart';

class ScopeModelBaseTab extends StatefulWidget {
  const ScopeModelBaseTab({super.key});

  @override
  State<ScopeModelBaseTab> createState() => _ScopeModelBaseTabState();
}

class _ScopeModelBaseTabState extends State<ScopeModelBaseTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Markdown(
          '''
          # ScopeModelBase, ScopeNotifierBase

          `ScopeModelBase` and `ScopeNotifierBase` are abstract base classes
          used to create custom providers that expose both the model and the
          provider widget itself to descendants.
          '''.trimIndent(),
        ),
        Expansion(
          title: const Markdown('**Usage**', selectable: false),
          initiallyExpanded: true,
          children: [
            Code(
              r'''
              import 'package:flutter/material.dart';
              import 'package:scopo/scopo.dart';

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

                // Create your own methods for convenient use.

                static ScopeContext<ModelScope, Model> get(
                  BuildContext context,
                ) =>
                    ScopeNotifierBase.get<ModelScope, Model>(context);

                static ScopeContext<ModelScope, Model> depend(
                  BuildContext context,
                ) =>
                    ScopeNotifierBase.depend<ModelScope, Model>(context);

                static V select<V extends Object?>(
                  BuildContext context,
                  V Function(ScopeContext<ModelScope, Model> e) selector,
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
                    dispose: (model) => model.dispose(),
                    builder: (context) => Center(
                      child: Row(
                        children: [
                          // We use `Builder` so that changes in `ModelScope`
                          // do not affect other widgets.
                          Builder(
                            builder: (context) {
                              final modelCounter = ModelScope.select<int>(
                                  context, (context) => context.model.modelCounter);

                              return Text('$modelCounter');
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
                                  context, (context) => context.widget.configCounter);

                              return Text('$configCounter');
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
                  );
                }
              }
              '''.trimIndent(),
            ),
            const Usage(),
            const SizedBox(height: 8),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
