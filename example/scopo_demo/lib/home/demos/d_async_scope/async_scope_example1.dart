import 'package:flutter/material.dart';

import 'counter_scope.dart';

class AsyncScopeExample1 extends StatelessWidget {
  static int _num = 0;

  const AsyncScopeExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        title: '$AsyncScopeExample1 (no scopeKey)',
        debugSource: AsyncScopeExample1,
        debugName: '${++_num}',
      ),
    );
  }
}
