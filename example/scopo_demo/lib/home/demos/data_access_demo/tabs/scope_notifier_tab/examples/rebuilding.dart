import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/constants.dart';
import '../../../../../../common/presentation/counter.dart';
import '../../../../../../common/presentation/expansion.dart';
import '../../../../../../common/presentation/markdown.dart';
import '../../../../../../common/presentation/titled_box_list.dart';
import '../../../../../../common/utils/string_extensions.dart';
import '../../common/non_const_consumers.dart';

final class Model with ChangeNotifier {
  var _a = 0;
  int get a => _a;

  var _b = 0;
  int get b => _b;

  void incrementA() {
    _a++;
    notifyListeners();
  }

  void incrementB() {
    _b++;
    notifyListeners();
  }
}

class ScopeListenableRebuildingExample extends StatefulWidget {
  const ScopeListenableRebuildingExample({super.key});

  @override
  State<ScopeListenableRebuildingExample> createState() =>
      _ScopeListenableRebuildingExampleState();
}

class _ScopeListenableRebuildingExampleState
    extends State<ScopeListenableRebuildingExample> {
  final model = Model();

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expansion(
      title: const Markdown(Constants.exampleTitle, selectable: false),
      initiallyExpanded: true,
      children: [
        Markdown(
          '''
          This example shows the precise impact of `ScopeNotifier` on widgets.
          '''.trimIndent(),
        ),
        const SizedBox(height: 8),
        Wrap(
          runSpacing: 8,
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ListenableBuilder(
              listenable: model,
              builder: (context, _) {
                return TitledBoxList(
                  title: const Text(Constants.modelTitle),
                  titleBackgroundColor: Theme.of(context).colorScheme.secondary,
                  titleForegroundColor:
                      Theme.of(context).colorScheme.onSecondary,
                  spacing: 0,
                  children: [
                    Counter(
                      title: 'a',
                      value: model.a,
                      increment: model.incrementA,
                    ),
                    Counter(
                      title: 'b',
                      value: model.b,
                      increment: model.incrementB,
                    ),
                  ],
                );
              },
            ),
            ScopeNotifier<Model>.value(
              value: model,
              builder: (context) {
                return NonConstConsumers(
                  selectA:
                      (context) =>
                          ScopeNotifier.select<Model, int>(context, (m) => m.a),
                  selectB:
                      (context) =>
                          ScopeNotifier.select<Model, int>(context, (m) => m.b),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
