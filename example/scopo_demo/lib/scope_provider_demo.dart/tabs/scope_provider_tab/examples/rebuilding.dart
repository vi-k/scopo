import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../common/presentation/box_list.dart';
import '../../../../common/presentation/counter.dart';
import '../../../../common/presentation/expansion.dart';
import '../../../../common/presentation/markdown.dart';
import '../../../../common/utils/string_extensions.dart';
import '../../common/constants.dart';
import '../../common/non_const_consumers.dart';

class ScopeProviderRebuildingExample extends StatefulWidget {
  const ScopeProviderRebuildingExample({
    super.key,
  });

  @override
  State<ScopeProviderRebuildingExample> createState() =>
      _ScopeProviderRebuildingExampleState();
}

class _ScopeProviderRebuildingExampleState
    extends State<ScopeProviderRebuildingExample> {
  var _a = 0;
  var _b = 0;

  int get a => _a;

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
    return ScopeProvider<_ScopeProviderRebuildingExampleState>.value(
      value: this,
      builder: (context) => Expansion(
        title: Markdown(
          '**Example**',
          selectable: false,
        ),
        initiallyExpanded: true,
        children: [
          Markdown(
            '''
            This example shows how all sub-tree widgets are rebuilt whenever
            there are changes in `ScopeProvider`.
            '''
                .trimIndent(),
          ),
          SizedBox(height: 8),
          Wrap(
            runSpacing: 8,
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              BoxList(
                title: Constants.modelTitle,
                titleBackgroundColor: Theme.of(context).colorScheme.secondary,
                titleForegroundColor: Theme.of(context).colorScheme.onSecondary,
                children: [
                  Counter(
                    title: 'a',
                    value: _a,
                    increment: incrementA,
                  ),
                  Counter(
                    title: 'b',
                    value: _b,
                    increment: incrementB,
                  ),
                ],
              ),
              NonConstConsumers(
                selectA: (context) => ScopeProvider.select<
                    _ScopeProviderRebuildingExampleState,
                    int>(context, (m) => m.a),
                selectB: (context) => ScopeProvider.select<
                    _ScopeProviderRebuildingExampleState,
                    int>(context, (m) => m.b),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
