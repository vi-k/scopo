import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/constants.dart';
import '../../../../../../common/presentation/consumer.dart';
import '../../../../../../common/presentation/counter.dart';
import '../../../../../../common/presentation/expansion.dart';
import '../../../../../../common/presentation/markdown.dart';
import '../../../../../../common/presentation/titled_box_list.dart';
import '../../../../../../common/utils/string_extensions.dart';

class ScopeModelProvidingExample extends StatefulWidget {
  const ScopeModelProvidingExample({super.key});

  static ScopeModelProvidingExampleState of(
    BuildContext context, {
    required bool listen,
  }) => ScopeModel.of<ScopeModelProvidingExampleState>(context, listen: listen);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(ScopeModelProvidingExampleState) selector,
  ) => ScopeModel.select<ScopeModelProvidingExampleState, V>(context, selector);

  @override
  State<ScopeModelProvidingExample> createState() =>
      ScopeModelProvidingExampleState();
}

class ScopeModelProvidingExampleState
    extends State<ScopeModelProvidingExample> {
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
  Widget build(
    BuildContext context,
  ) => ScopeModel<ScopeModelProvidingExampleState>.value(
    value: this,
    builder: (context) {
      return Expansion(
        initiallyExpanded: true,
        title: const Markdown(Constants.exampleTitle, selectable: false),
        children: [
          Markdown(
            '''
              In this example, widgets that are rebuilt when data changes
              **flash** at the moment of rebuilding. Accordingly, widgets that
              have not subscribed to changes cannot receive new data.
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
                titleForegroundColor: Theme.of(context).colorScheme.onSecondary,
                spacing: 0,
                children: [
                  Counter(title: 'a', value: _a, increment: incrementA),
                  Counter(title: 'b', value: _b, increment: incrementB),
                ],
              ),
              TitledBoxList(
                title: const Text(Constants.consumersTitle),
                titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
                titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
                children: const [
                  _ConstConsumerA(),
                  _ConstConsumerB(),
                  _ConstConsumerAB(),
                  _ConstConsumerAll(),
                ],
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _ConstConsumerA extends StatelessWidget {
  const _ConstConsumerA();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      blinkingColor: Theme.of(context).colorScheme.primary,
      title: const Text('dependent on [a]'),
      descriptions: [
        Markdown(
          fontSize: 12,
          '''
        * a = select(context, (m) => m.a);
        * b = of(context, listen: false).b;
        '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final a = ScopeModelProvidingExample.select<int>(context, (m) => m.a);
        final b = ScopeModelProvidingExample.of(context, listen: false).b;

        return Text('a=$a\nb=$b');
      },
    );
  }
}

class _ConstConsumerB extends StatelessWidget {
  const _ConstConsumerB();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      blinkingColor: Theme.of(context).colorScheme.primary,
      title: const Text('dependent on [b]'),
      descriptions: [
        Markdown(
          fontSize: 12,
          '''
        * a = of(context, listen: false).a;
        * b = select(context, (m) => m.b);
        '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final a = ScopeModelProvidingExample.of(context, listen: false).a;
        final b = ScopeModelProvidingExample.select<int>(context, (m) => m.b);

        return Text('a=$a\nb=$b');
      },
    );
  }
}

class _ConstConsumerAB extends StatelessWidget {
  const _ConstConsumerAB();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      blinkingColor: Theme.of(context).colorScheme.primary,
      title: const Text('dependent on [a, b]'),
      descriptions: [
        Markdown(
          fontSize: 12,
          '''
        * a = select(context, (m) => m.a);
        * b = select(context, (m) => m.b);
        '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final a = ScopeModelProvidingExample.select<int>(context, (m) => m.a);
        final b = ScopeModelProvidingExample.select<int>(context, (m) => m.b);

        return Text('a=$a\nb=$b');
      },
    );
  }
}

class _ConstConsumerAll extends StatelessWidget {
  const _ConstConsumerAll();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      blinkingColor: Theme.of(context).colorScheme.primary,
      title: const Text('dependent on entire model'),
      descriptions: [
        Markdown(
          fontSize: 12,
          '''
        * model = of(context, listen: true);
        * a = model.a;
        * b = model.b;
        '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final model = ScopeModelProvidingExample.of(context, listen: true);
        final a = model.a;
        final b = model.b;

        return Text('a=$a\nb=$b');
      },
    );
  }
}
