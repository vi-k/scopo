import 'package:flutter/material.dart';
import 'package:flutter_scope/flutter_scope.dart';

import '../home_counter.dart';
import '../home_navigation_block.dart';

final class HomeFeature extends StatelessWidget {
  final bool withNode;

  const HomeFeature({super.key, required this.withNode});

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: AppBar(
        title: Text('$HomeFeature ${withNode ? 'with node' : 'without node'}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              HomeCounter(),
              SizedBox(height: 20),
              HomeNavigationBlock(),
            ],
          ),
        ),
      ),
    );

    return withNode ? NavigationNode(child: child) : child;
  }
}
