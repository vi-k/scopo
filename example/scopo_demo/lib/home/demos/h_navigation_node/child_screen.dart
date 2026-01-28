import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'counter_view.dart';

final class ChildScreen extends StatelessWidget {
  final bool withNode;

  const ChildScreen({super.key, required this.withNode});

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: AppBar(
        title: Text(
          '$ChildScreen ${withNode ? 'with own node' : 'without own node'}',
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CounterView(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    return withNode ? NavigationNode(child: child) : child;
  }
}
