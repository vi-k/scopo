import 'package:flutter/material.dart';

import 'home.dart';

class HomeCounter extends StatelessWidget {
  const HomeCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Home.of(context),
      builder:
          (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IconButton(
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => Home.of(context).decrement(),
                icon: const Icon(Icons.remove_circle),
              ),
              Text(
                '${Home.of(context).counter}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => Home.of(context).increment(),
                icon: const Icon(Icons.add_circle),
              ),
            ],
          ),
    );
  }
}
