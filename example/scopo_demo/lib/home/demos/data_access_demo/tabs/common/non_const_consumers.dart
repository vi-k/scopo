import 'package:flutter/material.dart';

import '../../../../../common/constants.dart';
import '../../../../../common/presentation/markdown.dart';
import '../../../../../common/presentation/titled_box_list.dart';

class NonConstConsumers extends StatelessWidget {
  final int Function(BuildContext context) selectA;
  final int Function(BuildContext context) selectB;

  // ignore: prefer_const_constructors_in_immutables
  NonConstConsumers({super.key, required this.selectA, required this.selectB});

  @override
  Widget build(BuildContext context) {
    return TitledBoxList(
      title: const Text(Constants.nonConstConsumersTitle),
      titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
      titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
      blinkingColor: Theme.of(context).colorScheme.primary,
      children: [
        const Center(child: Markdown('This is **not** a consumer')),
        TitledBoxList(
          title: const Text('Non-constant child'),
          titleBackgroundColor: Theme.of(context).colorScheme.tertiary,
          titleForegroundColor: Theme.of(context).colorScheme.onTertiary,
          blinkingColor: Theme.of(context).colorScheme.primary,
          children: [
            const Center(child: Markdown('This is **not** a consumer')),
            Column(
              spacing: 8,
              children: [
                Builder(
                  builder: (context) {
                    final a = selectA(context);
                    return TitledBoxList(
                      title: const Text('Dependent on [a]'),
                      titleBackgroundColor:
                          Theme.of(context).colorScheme.primary,
                      titleForegroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                      blinkingColor: Theme.of(context).colorScheme.primary,
                      children: [Center(child: Text('a=$a'))],
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    final b = selectB(context);
                    return TitledBoxList(
                      title: const Text('Dependent on [b]'),
                      titleBackgroundColor:
                          Theme.of(context).colorScheme.primary,
                      titleForegroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                      blinkingColor: Theme.of(context).colorScheme.primary,
                      children: [Center(child: Text('b=$b'))],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
