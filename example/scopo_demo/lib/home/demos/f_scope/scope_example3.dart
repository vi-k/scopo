import 'package:flutter/material.dart';

import 'counter_scope.dart';

int _num = 0;

class ScopeExample3 extends StatefulWidget {
  const ScopeExample3({super.key});

  @override
  State<ScopeExample3> createState() => _ScopeExample3State();
}

class _ScopeExample3State extends State<ScopeExample3> {
  @override
  void initState() {
    super.initState();
    _num++;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: CounterScope(
              scopeKey: ScopeExample3,
              title: '$ScopeExample3 (parent & child)',
              childScope: Center(
                child: CounterScope(
                  debugSource: ScopeExample3,
                  debugName: 'child $_num',
                ),
              ),
              debugSource: ScopeExample3,
              debugName: 'parent $_num',
            ),
          ),
        ],
      ),
    );
  }
}
