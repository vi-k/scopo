import 'package:flutter/material.dart';

import 'counter_scope.dart';

int _num = 0;

class LiteScopeExample3 extends StatefulWidget {
  const LiteScopeExample3({super.key});

  @override
  State<LiteScopeExample3> createState() => _LiteScopeExample3State();
}

class _LiteScopeExample3State extends State<LiteScopeExample3> {
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
              scopeKey: LiteScopeExample3,
              title: '$LiteScopeExample3 (scopeKey + parent & child)',
              childScope: Center(
                child: CounterScope(
                  debugSource: LiteScopeExample3,
                  debugName: 'child $_num',
                ),
              ),
              debugSource: LiteScopeExample3,
              debugName: 'parent $_num',
            ),
          ),
        ],
      ),
    );
  }
}
