import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../common/presentation/expansion.dart';
import '../../../../../common/presentation/markdown.dart';
import '../../../../common/constants.dart';
import '../../../../common/presentation/box.dart';
import '../../../../common/presentation/titled_box_list.dart';

enum ScopeStateBuilderExampleState {
  initial,
  inProgress,
  success,
  error,
}

class ScopeStateBuilderExample extends StatelessWidget {
  const ScopeStateBuilderExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      ScopeStateBuilder<ScopeStateBuilderExampleState>(
        initialState: ScopeStateBuilderExampleState.initial,
        selfDependence: false,
        builder: (context, notifier) => Expansion(
          initiallyExpanded: true,
          title: const Markdown('**Example**', selectable: false),
          children: [
            Wrap(
              runSpacing: 8,
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ListenableBuilder(
                  listenable: notifier,
                  builder: (context, _) => TitledBoxList(
                    title: Constants.modelTitle,
                    titleBackgroundColor:
                        Theme.of(context).colorScheme.secondary,
                    titleForegroundColor:
                        Theme.of(context).colorScheme.onSecondary,
                    children: [
                      for (final state in ScopeStateBuilderExampleState.values)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: notifier.state == state
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                            foregroundColor: notifier.state == state
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                          ),
                          onPressed: () {
                            notifier.update(state);
                          },
                          child: Text(state.name),
                        ),
                    ],
                  ),
                ),
                TitledBoxList(
                  title: 'State builder',
                  titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
                  titleForegroundColor:
                      Theme.of(context).colorScheme.onTertiary,
                  blinkingColor: Theme.of(context).colorScheme.tertiary,
                  children: const [
                    _ConstConsumer(),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}

class _ConstConsumer extends StatelessWidget {
  const _ConstConsumer();

  @override
  Widget build(BuildContext context) {
    final state = ScopeStateBuilder.stateOf<ScopeStateBuilderExampleState>(
      context,
      listen: true,
    );

    return Box(
      blinkingColor: Theme.of(context).colorScheme.primary,
      child: Text(
        state.name,
        textAlign: TextAlign.center,
      ),
    );
  }
}
