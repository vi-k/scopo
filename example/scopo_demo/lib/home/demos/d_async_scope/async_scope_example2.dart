import 'package:flutter/material.dart';

import 'counter_scope.dart';

class AsyncScopeExample2 extends StatelessWidget {
  static int _num = 0;

  const AsyncScopeExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        scopeKey: AsyncScopeExample2,
        title: '$AsyncScopeExample2 (only one working scope)',
        debugSource: AsyncScopeExample2,
        debugName: '${++_num}',
      ),
    );
  }
}
