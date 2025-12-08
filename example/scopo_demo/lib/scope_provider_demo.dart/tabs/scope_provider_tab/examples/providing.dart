import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../common/presentation/box_list.dart';
import '../../../../common/presentation/consumer.dart';
import '../../../../common/presentation/counter.dart';
import '../../../../common/presentation/expansion.dart';
import '../../../../common/presentation/markdown.dart';
import '../../../../common/utils/string_extensions.dart';
import '../../common/constants.dart';

class ScopeProviderProvidingExample extends StatefulWidget {
  const ScopeProviderProvidingExample({
    super.key,
  });

  @override
  State<ScopeProviderProvidingExample> createState() =>
      _ScopeProviderProvidingExampleState();
}

class _ScopeProviderProvidingExampleState
    extends State<ScopeProviderProvidingExample> {
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
    return ScopeProvider<_ScopeProviderProvidingExampleState>.value(
      value: this,
      builder: (context) => Expansion(
        initiallyExpanded: true,
        title: Markdown(
          '**Example**',
          selectable: false,
        ),
        children: [
          Markdown(
            '''
            In this example, widgets that are rebuilt when data changes
            **flash** at the moment of rebuilding. Accordingly, widgets that
            have not subscribed to changes cannot receive new data.
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
              BoxList(
                title: Constants.consumersTitle,
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
      ),
    );
  }
}

class _ConstConsumerA extends StatelessWidget {
  const _ConstConsumerA();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      blinkingColor: Theme.of(context).colorScheme.primary,
      title: Text('dependent on [a]'),
      description: [
        Markdown(
          '''
          * a = select(context, (m) => m.a);
          * b = get(context).b;
          '''
              .trimIndent(),
        ),
      ],
      consumerValue: (context) {
        final a =
            ScopeProvider.select<_ScopeProviderProvidingExampleState, int>(
                context, (m) => m.a);
        final b =
            ScopeProvider.get<_ScopeProviderProvidingExampleState>(context).b;

        return 'a=$a\nb=$b';
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
      title: Text('dependent on [b]'),
      description: [
        Markdown(
          '''
          * a = get(context).a;
          * b = select(context, (m) => m.b);
          '''
              .trimIndent(),
        ),
      ],
      consumerValue: (context) {
        final a =
            ScopeProvider.get<_ScopeProviderProvidingExampleState>(context).a;
        final b =
            ScopeProvider.select<_ScopeProviderProvidingExampleState, int>(
                context, (m) => m.b);

        return 'a=$a\nb=$b';
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
      title: Text('dependent on [a, b]'),
      description: [
        Markdown(
          '''
          * a = select(context, (m) => m.a);
          * b = select(context, (m) => m.b);
          '''
              .trimIndent(),
        ),
      ],
      consumerValue: (context) {
        final a =
            ScopeProvider.select<_ScopeProviderProvidingExampleState, int>(
                context, (m) => m.a);
        final b =
            ScopeProvider.select<_ScopeProviderProvidingExampleState, int>(
                context, (m) => m.b);

        return 'a=$a\nb=$b';
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
      title: Text('dependent on entire model'),
      description: [
        Markdown(
          '''
          * model = depend(context);
          * a = model.a;
          * b = model.b;
          '''
              .trimIndent(),
        ),
      ],
      consumerValue: (context) {
        final model =
            ScopeProvider.depend<_ScopeProviderProvidingExampleState>(context);
        final a = model.a;
        final b = model.b;

        return 'a=$a\nb=$b';
      },
    );
  }
}
