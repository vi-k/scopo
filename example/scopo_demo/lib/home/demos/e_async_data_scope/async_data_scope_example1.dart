import 'package:flutter/material.dart';

import 'counter_scope.dart';

class AsyncDataScopeExample1 extends StatelessWidget {
  static int _num = 0;

  const AsyncDataScopeExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        title: '$AsyncDataScopeExample1 (no scopeKey)',
        debugSource: AsyncDataScopeExample1,
        debugName: '${++_num}',
      ),
    );
  }
}
