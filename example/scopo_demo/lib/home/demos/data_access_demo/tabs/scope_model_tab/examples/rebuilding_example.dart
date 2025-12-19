import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/constants.dart';
import '../../../../../../common/presentation/counter.dart';
import '../../../../../../common/presentation/expansion.dart';
import '../../../../../../common/presentation/markdown.dart';
import '../../../../../../common/presentation/titled_box_list.dart';
import '../../../../../../common/utils/string_extensions.dart';
import '../../common/non_const_consumers.dart';

class ScopeModelRebuildingExample extends StatefulWidget {
  const ScopeModelRebuildingExample({super.key});

  @override
  State<ScopeModelRebuildingExample> createState() =>
      _ScopeModelRebuildingExampleState();
}

class _ScopeModelRebuildingExampleState
    extends State<ScopeModelRebuildingExample> {
  var _a = 0;
  int get a => _a;

  var _b = 0;
  int get b => _b;

  void incrementA() {
    setState(() {
      _a++;
    });
  }

  void incrementB() {
    setState(() {
      _b++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopeModel<_ScopeModelRebuildingExampleState>.value(
      value: this,
      builder: (context) {
        return Expansion(
          title: const Markdown(Constants.exampleTitle, selectable: false),
          initiallyExpanded: true,
          children: [
            Markdown(
              '''
              This example shows how all sub-tree widgets are rebuilt whenever
              there are changes in `ScopeModel`.
              '''.trimIndent(),
            ),
            const SizedBox(height: 8),
            Wrap(
              runSpacing: 8,
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                TitledBoxList(
                  title: const Text(Constants.modelTitle),
                  titleBackgroundColor: Theme.of(context).colorScheme.secondary,
                  titleForegroundColor:
                      Theme.of(context).colorScheme.onSecondary,
                  spacing: 0,
                  children: [
                    Counter(title: 'a', value: _a, increment: incrementA),
                    Counter(title: 'b', value: _b, increment: incrementB),
                  ],
                ),
                NonConstConsumers(
                  selectA:
                      (context) => ScopeModel.select<
                        _ScopeModelRebuildingExampleState,
                        int
                      >(context, (m) => m.a),
                  selectB:
                      (context) => ScopeModel.select<
                        _ScopeModelRebuildingExampleState,
                        int
                      >(context, (m) => m.b),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
