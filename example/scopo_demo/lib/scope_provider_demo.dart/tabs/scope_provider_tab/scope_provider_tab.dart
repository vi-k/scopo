import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/common/presentation/markdown.dart';
import 'package:scopo_demo/common/utils/string_extensions.dart';
import 'package:scopo_demo/scope_provider_demo.dart/tabs/scope_provider_tab/examples/providing.dart';

import '../../../common/presentation/code.dart';
import '../../../common/presentation/code_block.dart';
import '../../../common/presentation/expansion.dart';
import '../../../common/presentation/markdown_block.dart';
import 'examples/rebuilding.dart';
import 'examples/usage.dart';

class ScopeProviderTab extends StatefulWidget {
  const ScopeProviderTab({super.key});

  @override
  State<ScopeProviderTab> createState() => _ScopeProviderTabState();
}

class _ScopeProviderTabState extends State<ScopeProviderTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ScopeProvider<_ScopeProviderTabState>.value(
      value: this,
      builder: (context) => ListView(
        padding: EdgeInsets.all(8),
        children: [
          MarkdownBlock(
            indent: 0,
            '''
            # ScopeProvider<Model extends Object>

            `ScopeProvider` is a dependency injection widget that provides
            values to the widget tree. It is based on `InheritedWidget` with
            all its advantages and **disadvantages**.
            '''
                .trimIndent(),
          ),
          MarkdownBlock(
            indent: 24,
            '''
            ## Providing and receiving data

            It offers three ways to access the provided value, giving you
            fine-grained control over widget rebuilds:

            * **`ScopeProvider.get<T>(context)`**:
              * **Does NOT** subscribe to changes.
              * Use this for reading values in callbacks (e.g., `onPressed`)
                where you don't need the widget to rebuild when the value
                changes.

            * **`ScopeProvider.depend<T>(context)`**:
              * **Subscribes** to the provider.
              * The widget will rebuild whenever the `ScopeProvider` itself
                rebuilds and notifies clients.

            * **`ScopeProvider.select<T, V>(context, (model) => model.value)`**:
              * **Selectively subscribes** to a specific part of the value.
              * The widget will **only** rebuild if the selected value `V`
                changes.
              * This is crucial for optimizing performance by preventing
                unnecessary rebuilds.
            '''
                .trimIndent(),
          ),
          const ScopeProviderProvidingExample(),
          MarkdownBlock(
            indent: 24,
            '''
            ## Rebuilding when changing the model

            `ScopeProvider` can only detect changes in the model when the
            `ScopeProvider` is rebuilt. That is, to notify subscribers of
            changes, you need to force `ScopeProvider` (as well as
            `InheritedWidget`) to rebuild. For example, by using `setState` on
            the parent `StatefulWidget`. But in this case, all widgets in the
            subtree will also be rebuilt, even those that are not subscribed to
            `ScopeProvider`.

            This is a significant limitation, so it is recommended to use
            `ScopeProvider` only in widget trees with **small nesting depths**
            or to create a **constant** tree:
            '''
                .trimIndent(),
          ),
          CodeBlock(
            '''
            @override
            Widget build(BuildContext context) {
              return ScopeProvider<ModelScopeState>.value(
                value: this,
                builder: (context) => const _Content(),
              );
            }
            '''
                .trimIndent(),
          ),
          const ScopeProviderRebuildingExample(),
          MarkdownBlock(
            indent: 24,
            '''
            ## Create and dispose the model

            `ScopeProvider` allows you to use a ready-made model using the
            `ScopeProvider.value` constructor:
            '''
                .trimIndent(),
          ),
          CodeBlock(
            '''
            @override
            Widget build(BuildContext context) {
              return ScopeProvider<ModelScopeState>.value(
                value: this,
                builder: (context) => ...,
              );
            }
            '''
                .trimIndent(),
          ),
          MarkdownBlock(
            '''
            Or to create a model by passing the `create` callback, and then
            dispose of it by passing the `dispose` callback.
            '''
                .trimIndent(),
          ),
          CodeBlock(
            '''
            @override
            Widget build(BuildContext context) {
              return ScopeProvider<ModelScopeState>(
                create: (context) => Model(),
                dispose: (model) => model.dispose(),
                builder: (context) => ...,
              );
            }
            '''
                .trimIndent(),
          ),
          MarkdownBlock(
            indent: 24,
            '''
            ## Usage

            The following code demonstrates a complete example of the correct
            use of `ScopeProvider` to avoid the limitation of `InheritedWidget`:
            '''
                .trimIndent(),
          ),
          Expansion(
            title: Markdown('**Usage**', selectable: false),
            contentPadding: EdgeInsets.zero,
            initiallyExpanded: true,
            children: [
              Code(
                '''
                import 'package:flutter/material.dart';
                import 'package:scopo/scopo.dart';

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
                    return Row(
                      children: [
                        // We use `Builder` so that changes in `ScopeProvider`
                        // do not affect other widgets.
                        Builder(
                          builder: (context) {
                            final counter = ScopeProvider.select<ModelScopeState, int>(
                                context, (m) => m.counter);
                            return Text('\$counter');
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
                    )
                  }
                }
                '''
                    .trimIndent(),
              ),
              ModelScope(),
              SizedBox(height: 8),
            ],
          ),
          MarkdownBlock(
            '''
            To keep `_Content` constant, do not pass parameters through the
            `_Content` constructor. Access them using `ScopeProvider`:
            '''
                .trimIndent(),
          ),
          CodeBlock(
            '''
            class ModelScope extends StatefulWidget {
              const ModelScope({super.key, required this.param});

              final int param;

              // ...
            }

            // ...

            final param = ScopeProvider.select<ModelScopeState, int>(
                context,
                (m) => m.widget.param,
            );
            '''
                .trimIndent(),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
