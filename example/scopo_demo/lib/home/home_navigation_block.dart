import 'package:flutter/material.dart';

import 'home.dart';
import 'home_deps.dart';
import 'home_feature/home_feature.dart';

class HomeNavigationBlock extends StatelessWidget {
  const HomeNavigationBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Home.of(context).openDialog(context),
          child: const Text('Dialog'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Home.of(context).openModalBottomSheet(context),
          child: const Text('Bottom sheet'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Home.of(context).openBottomSheet(context),
          child: const Text('(not modal) Bottom sheet'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // ignore: discarded_futures
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const HomeFeature(withNode: true),
              ),
            );
          },
          child: const Text('Feature with navigation node'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // ignore: discarded_futures
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const HomeFeature(withNode: false),
              ),
            );
          },
          child: const Text('Feature w/o navigation node'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop(123)
                  : null,
          child: const Text('close screen'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // ignore: discarded_futures
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder:
                    (_) =>
                        const Home(init: HomeDependencies.init, isRoot: false),
              ),
            );
          },
          child: Text('Open another $Home'),
        ),
      ],
    );
  }
}
