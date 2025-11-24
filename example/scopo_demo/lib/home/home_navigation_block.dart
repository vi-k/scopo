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
          child: Text('Dialog'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Home.of(context).openModalBottomSheet(context),
          child: Text('Bottom sheet'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Home.of(context).openBottomSheet(context),
          child: Text('(not modal) Bottom sheet'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomeFeature(withNode: true)),
            );
          },
          child: Text('Feature with navigation node'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomeFeature(withNode: false)),
            );
          },
          child: Text('Feature w/o navigation node'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop(123)
                  : null,
          child: Text('close screen'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        Home(tag: 'second', init: HomeDeps.init, isRoot: false),
              ),
            );
          },
          child: Text('Open another $Home'),
        ),
      ],
    );
  }
}
