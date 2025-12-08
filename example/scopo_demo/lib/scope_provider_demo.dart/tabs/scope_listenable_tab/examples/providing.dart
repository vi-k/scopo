import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../common/presentation/box_list.dart';
import '../../../../common/presentation/consumer.dart';
import '../../../../common/presentation/counter.dart';
import '../../../../common/presentation/expansion.dart';
import '../../../../common/presentation/markdown.dart';
import '../../../../common/utils/string_extensions.dart';
import '../../common/constants.dart';

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

class ScopeListenableProvidingExample extends StatelessWidget {
  const ScopeListenableProvidingExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScopeListenableProvider<Model>(
      create: (context) => Model(),
      dispose: (model) => model.dispose(),
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
              ListenableBuilder(
                listenable: ScopeListenableProvider.get<Model>(context),
                builder: (context, _) {
                  final model = ScopeListenableProvider.get<Model>(context);
                  return BoxList(
                    title: Constants.modelTitle,
                    titleBackgroundColor:
                        Theme.of(context).colorScheme.secondary,
                    titleForegroundColor:
                        Theme.of(context).colorScheme.onSecondary,
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
              BoxList(
                title: Constants.consumersTitle,
                titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
                titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
                blinkingColor: Theme.of(context).colorScheme.tertiary,
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
      title: Text('consumer dependent on [a]'),
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
            ScopeListenableProvider.select<Model, int>(context, (m) => m.a);
        final b = ScopeListenableProvider.get<Model>(context).b;

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
      title: Text('consumer dependent on [b]'),
      description: [
        Markdown(
          '''
          dependent on **b**:
          * a = get(context).a;
          * b = select(context, (m) => m.b);
          '''
              .trimIndent(),
        ),
      ],
      consumerValue: (context) {
        final a = ScopeListenableProvider.get<Model>(context).a;
        final b =
            ScopeListenableProvider.select<Model, int>(context, (m) => m.b);

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
      title: Text('consumer dependent on [a, b]'),
      description: [
        Markdown(
          '''
          dependent on **a** and **b**:
          * a = select(context, (m) => m.a);
          * b = select(context, (m) => m.b);
          '''
              .trimIndent(),
        ),
      ],
      consumerValue: (context) {
        final a =
            ScopeListenableProvider.select<Model, int>(context, (m) => m.a);
        final b =
            ScopeListenableProvider.select<Model, int>(context, (m) => m.b);

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
      title: Text('consumer dependent on entire model'),
      description: [
        Markdown(
          '''
          dependent on **entire model**:
          * m = depend(context);
          * a = m.a;
          * b = m.b;
          '''
              .trimIndent(),
        ),
      ],
      consumerValue: (context) {
        final model = ScopeListenableProvider.depend<Model>(context);
        final a = model.a;
        final b = model.b;

        return 'a=$a\nb=$b';
      },
    );
  }
}
