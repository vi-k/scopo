import 'package:flutter/material.dart';

import '../../../../../common/presentation/code.dart';
import '../../../../../common/presentation/expansion.dart';
import '../../../../../common/presentation/markdown.dart';
import '../../../../../common/presentation/markdown_block.dart';
import '../../../../../common/utils/string_extensions.dart';
import 'examples/providing.dart';
import 'examples/rebuilding.dart';
import 'examples/usage.dart';

class ScopeNotifierTab extends StatefulWidget {
  const ScopeNotifierTab({super.key});

  @override
  State<ScopeNotifierTab> createState() => _ScopeNotifierTabState();
}

class _ScopeNotifierTabState extends State<ScopeNotifierTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        MarkdownBlock(
          indent: 0,
          '''
          # ScopeNotifier<Model extends Listenable>

          `ScopeNotifier` is optimized for `Listenable` objects.
          It automatically listens to the object and rebuilds dependents
          when the object notifies listeners.

          Its purpose is similar to that of `InheritedNotifier`, but it is
          not based on it. `ScopeNotifier`, unlike `InheritedNotifier`, adds
          the ability to depend only on part of the model, i.e. to use
          `select`.
          '''.trimIndent(),
        ),
        MarkdownBlock(
          indent: 24,
          '''
          ## Providing and receiving data

          It offers three ways to access the provided value, giving you
          fine-grained control over widget rebuilds:

          * **`ScopeNotifier.get<T>(context)`**:
            * **Does NOT** subscribe to changes.
            * Use this for reading values in callbacks (e.g., `onPressed`)
              where you don't need the widget to rebuild when the value
              changes.

          * **`ScopeNotifier.depend<T>(context)`**:
            * **Subscribes** to the provider.
            * The widget will rebuild whenever the `ScopeNotifier`
              notifies clients.

          * **`ScopeNotifier.select<T, V>(context, (model) => ...)`**:
            * **Selectively subscribes** to a specific part of the value.
            * The widget will **only** rebuild if the selected value `V`
              changes.
            * This is crucial for optimizing performance by preventing
              unnecessary rebuilds.
          '''.trimIndent(),
        ),
        const ScopeListenableProvidingExample(),
        MarkdownBlock(
          indent: 24,
          '''
          ## Rebuilding when changing the model

          `ScopeNotifier` allows you to subscribe to
          a `Listenable` object. When receiving a signal from `Listenable`,
          unlike `ScopeModel`, it rebuilds only its dependent widgets.
          '''.trimIndent(),
        ),
        const ScopeListenableRebuildingExample(),
        MarkdownBlock(
          indent: 24,
          '''
          ## Create and dispose the model

          Like `ScopeModel`, `ScopeNotifier` can pass a ready-made value
          using `ScopeNotifier.value` constructor. But you can also create
          a model when building the tree using `create` callback. In this
          case, it is important not to forget to dispose of your model using
          `dispose` callback.
          '''.trimIndent(),
        ),
        MarkdownBlock(
          indent: 24,
          '''
          ## Usage

          The following code demonstrates how `ScopeNotifier` can be used.
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
                    builder: (context) => Row(
                      children: [
                        // We use `Builder` so that changes in `ScopeNotifier`
                        // do not affect other widgets.
                        Builder(
                          builder: (context) {
                            final counter = ScopeNotifier.select<Model, int>(
                                context, (m) => m.counter);
                            return Text('$counter');
                          },
                        ),
                        IconButton(
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            ScopeNotifier.get<Model>(context).increment();
                          },
                          icon: const Icon(Icons.add_circle),
                        ),
                      ],
                    ),
                  );
                }
              }
              '''.trimIndent(),
            ),
            const ModelScope(),
            const SizedBox(height: 8),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
