import 'package:flutter/material.dart';

import '../../../common/presentation/code.dart';
import '../../../common/presentation/expansion.dart';
import '../../../common/presentation/markdown.dart';
import '../../../common/presentation/markdown_block.dart';
import '../../../common/utils/string_extensions.dart';
// import '../../model/listenable_model.dart';
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
      padding: EdgeInsets.all(8),
      children: [
        Markdown(
          '''
          ### ScopeNotifier<Model extends ChangeNotifier>

          `ScopeNotifier` differs from `ScopeListenableProvider` only in
          that it uses `ChangeNotifier` descendants as models and
          automatically disposes them if they were created using `create`
          callback.
          '''
              .trimIndent(),
        ),
        MarkdownBlock(
          indent: 24,
          '''
          ## Usage

          The following code demonstrates how `ScopeNotifier` can be used.
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
                    // With `ScopeNotifier`, content can be either
                    // constant or non-constant.
                    builder: (context) => Row(
                      children: [
                        // We use `Builder` so that changes in `ScopeNotifier`
                        // do not affect other widgets.
                        Builder(
                          builder: (context) {
                            final counter = ScopeNotifier.select<Model, int>(
                                context, (m) => m.counter);
                            return Text('\$counter');
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
              '''
                  .trimIndent(),
            ),
            ModelScope(),
            SizedBox(height: 8),
          ],
        ),
        SizedBox(height: 32),
      ],
    );
  }
}
