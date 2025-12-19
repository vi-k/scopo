import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/constants.dart';
import '../../../../../../common/presentation/consumer.dart';
import '../../../../../../common/presentation/counter.dart';
import '../../../../../../common/presentation/expansion.dart';
import '../../../../../../common/presentation/markdown.dart';
import '../../../../../../common/presentation/titled_box_list.dart';
import '../../../../../../common/utils/string_extensions.dart';

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
  const ScopeListenableProvidingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeNotifier<Model>(
      create: (context) => Model(),
      dispose: (model) => model.dispose(),
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
                ListenableBuilder(
                  listenable: ScopeNotifier.of<Model>(context, listen: false),
                  builder: (context, _) {
                    final model = ScopeNotifier.of<Model>(
                      context,
                      listen: true,
                    );
                    return TitledBoxList(
                      title: const Text(Constants.modelTitle),
                      titleBackgroundColor:
                          Theme.of(context).colorScheme.secondary,
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
                TitledBoxList(
                  title: const Text(Constants.consumersTitle),
                  titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
                  titleForegroundColor:
                      Theme.of(context).colorScheme.onTertiary,
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
        );
      },
    );
  }
}

class _ConstConsumerA extends StatelessWidget {
  const _ConstConsumerA();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      blinkingColor: Theme.of(context).colorScheme.primary,
      title: const Text('consumer dependent on [a]'),
      descriptions: [
        Markdown(
          '''
            * a = select(context, (m) => m.a);
            * b = get(context).b;
            '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final a = ScopeNotifier.select<Model, int>(context, (m) => m.a);
        final b = ScopeNotifier.of<Model>(context, listen: false).b;

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
      title: const Text('consumer dependent on [b]'),
      descriptions: [
        Markdown(
          '''
          dependent on **b**:
          * a = get(context).a;
          * b = select(context, (m) => m.b);
          '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final a = ScopeNotifier.of<Model>(context, listen: false).a;
        final b = ScopeNotifier.select<Model, int>(context, (m) => m.b);

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
      title: const Text('consumer dependent on [a, b]'),
      descriptions: [
        Markdown(
          '''
          dependent on **a** and **b**:
          * a = select(context, (m) => m.a);
          * b = select(context, (m) => m.b);
          '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final a = ScopeNotifier.select<Model, int>(context, (m) => m.a);
        final b = ScopeNotifier.select<Model, int>(context, (m) => m.b);

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
      title: const Text('consumer dependent on entire model'),
      descriptions: [
        Markdown(
          '''
          dependent on **entire model**:
          * m = depend(context);
          * a = m.a;
          * b = m.b;
          '''.trimIndent(),
        ),
      ],
      builder: (context) {
        final model = ScopeNotifier.of<Model>(context, listen: true);
        final a = model.a;
        final b = model.b;

        return Text('a=$a\nb=$b');
      },
    );
  }
}
