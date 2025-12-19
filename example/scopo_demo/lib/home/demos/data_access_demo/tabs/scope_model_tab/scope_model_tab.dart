import 'package:flutter/material.dart';

import '../../../../../common/presentation/code.dart';
import '../../../../../common/presentation/code_block.dart';
import '../../../../../common/presentation/expansion.dart';
import '../../../../../common/presentation/markdown.dart';
import '../../../../../common/presentation/markdown_block.dart';
import '../../../../../common/utils/string_extensions.dart';
import 'examples/providing_example.dart';
import 'examples/rebuilding_example.dart';
import 'examples/usage_example.dart';

class ScopeModelTab extends StatefulWidget {
  const ScopeModelTab({super.key});

  @override
  State<ScopeModelTab> createState() => _ScopeModelTabState();
}

class _ScopeModelTabState extends State<ScopeModelTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      children: [
        MarkdownBlock(
          indent: 0,
          '''
          # ScopeModel<Model extends Object>

          The main thing you need to create a scope is to provide access to
          the scope data. This ensures that every widget within the scope can
          easily access it.

          `ScopeModel` is a dependency injection widget based on
          `InheritedWidget` that provides values to the widget tree.

          But unlike `InheritedWidget`, it provides the ability to depend only
          on part of the model using `select`.

          It also unlike `InheritedWidget` and `Provider` uses `builder`
          instead of `child` to create a descendant, passing it the `context`
          in which the provider is already present. This avoids a common
          mistake made by novice developers who try to retrieve data from a
          `context` that does not have a provider:
          '''.trimIndent(),
        ),
        CodeBlock(
          '''
          @override
          Widget build(BuildContext context) {
            return Provider<Widget>.value(
              value: Text('Hello'),
              child: Provider.of<Widget>(context), // ProviderNotFoundException
            );
          }
          '''.trimIndent(),
        ),
        MarkdownBlock(
          indent: 24,
          '''
          ## Creating

          `ScopeModel` allows you to use a ready-made model using the
          `ScopeModel.value` constructor:
          '''.trimIndent(),
        ),
        CodeBlock(
          '''
          @override
          Widget build(BuildContext context) {
            return ScopeModel<ModelScopeState>.value(
              value: this,
              builder: (context) => ...,
            );
          }
          '''.trimIndent(),
        ),
        MarkdownBlock(
          '''
          Or to create a model by passing the `create` and `dispose` callbacks.
          '''.trimIndent(),
        ),
        CodeBlock(
          '''
          @override
          Widget build(BuildContext context) {
            return ScopeModel<ModelScopeState>(
              create: (context) => Model(),
              dispose: (model) => model.dispose(),
              builder: (context) => ...,
            );
          }
          '''.trimIndent(),
        ),
        MarkdownBlock(
          indent: 24,
          '''
          ## Data access

          It offers three ways to access the provided value, giving you
          fine-grained control over widget rebuilds:

          * **`ScopeModel.of<T>(context, listen: false)`**:
            * **Does NOT** subscribe to changes.
            * Use this for reading values in callbacks (e.g., `onPressed`)
              where you don't need the widget to rebuild when the value
              changes.

          * **`ScopeModel.of<T>(context, listen: true)`**:
            * **Subscribes** to the provider.
            * The widget will rebuild whenever the `ScopeModel` itself
              rebuilds and notifies clients.
            * **Note**: In most cases, it is better to use `select` instead of
              this method.

          * **`ScopeModel.select<T, V>(context, (model) => model.value)`**:
            * **Selectively subscribes** to a specific part of the value.
            * The widget will **only** rebuild if the selected value `V`
              changes.
            * This is crucial for optimizing performance by preventing
              unnecessary rebuilds.
          '''.trimIndent(),
        ),
        const ScopeModelProvidingExample(),
        MarkdownBlock(
          indent: 24,
          '''
          ## Rebuilding when changing the model

          `ScopeModel` can only detect changes in the model when it is
          rebuilt. That is, to notify subscribers of changes, you need to
          force `ScopeModel` (as well as `InheritedWidget` and `Provider`)
          to rebuild.

          For example, by using `setState` on the parent `StatefulWidget`. But
          in this case, all widgets in the subtree will also be rebuilt, even
          those that are not subscribed to `ScopeModel`.

          This is a significant limitation, so it is recommended to use
          `ScopeModel` only in **lightweight** widget trees or to create
          a **constant** tree:
          '''.trimIndent(),
        ),
        CodeBlock(
          '''
          @override
          Widget build(BuildContext context) {
            return ScopeModel<ModelScopeState>.value(
              value: this,
              builder: (context) => const _Content(),
            );
          }
          '''.trimIndent(),
        ),
        const ScopeModelRebuildingExample(),

        MarkdownBlock(
          indent: 24,
          '''
          ## Usage

          The following code demonstrates a complete example of creating
          a scope using `ScopeModel` and bypassing the `InheritedWidget`
          limitation.
          '''.trimIndent(),
        ),
        Expansion(
          title: const Markdown('**Usage**', selectable: false),
          contentPadding: EdgeInsets.zero,
          initiallyExpanded: true,
          children: [
            Code(
              r'''
              import 'package:flutter/material.dart';
              import 'package:scopo/scopo.dart';

              class CounterScope extends StatefulWidget {
                const CounterScope({super.key});

                // To obtain data, you can use the
                // `ScopeModel.of<CounterScopeState>` and
                // `ScopeModel.select<CounterScopeState>` methods
                // directly, but when working with a scope, its own
                // methods `CounterScope.of` and `CounterScope.select`
                // are preferable.

                static CounterScopeState of(BuildContext context) =>
                    ScopeModel.of<CounterScopeState>(
                      context,
                      listen: false,
                    );

                static V select<V extends Object?>(
                  BuildContext context,
                  V Function(CounterScopeState) selector,
                ) => ScopeModel.select<CounterScopeState, V>(
                  context,
                  selector,
                );

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
                    builder: (context) => const _Content(),
                  );
                }
              }

              class _Content extends StatelessWidget {
                const _Content();

                @override
                Widget build(BuildContext context) {
                  return Row(
                    children: [
                      // We use `Builder` so that changes in
                      // `ScopeModel` do not affect other widgets.
                      Builder(
                        builder: (context) {
                          final counter = CounterScope.select<int>(
                            context,
                            (m) => m.counter,
                          );
                          return Text('$counter');
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
                  )
                }
              }
              '''.trimIndent(),
            ),
            const CounterScope(),
            const SizedBox(height: 8),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
