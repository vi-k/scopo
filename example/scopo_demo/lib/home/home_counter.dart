import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'home.dart';

class HomeCounter extends StatefulWidget {
  const HomeCounter({super.key});

  @override
  State<HomeCounter> createState() => _HomeCounterState();
}

class _HomeCounterState extends State<HomeCounter> {
  @override
  Widget build(BuildContext context) => ListenableAspectBuilder(
    listenable: Home.of(context),
    aspect: (scope) => scope.counter,
    builder:
        (context, scope, counter, _) => Row(
          mainAxisSize: MainAxisSize.min,
          textBaseline: TextBaseline.alphabetic,
          children: [
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              onPressed: scope.decrement,
              icon: const Icon(Icons.remove_circle),
            ),
            Text(
              '${scope.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              onPressed: scope.increment,
              icon: const Icon(Icons.add_circle),
            ),
          ],
        ),
  );
}
