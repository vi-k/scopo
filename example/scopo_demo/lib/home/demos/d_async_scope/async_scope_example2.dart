import 'package:flutter/material.dart';

import 'counter_scope.dart';

class AsyncScopeExample2 extends StatelessWidget {
  static int _num = 0;

  const AsyncScopeExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        debugSource: AsyncScopeExample2,
        debugName: '2.${++_num}',
        scopeKey: AsyncScopeExample2,
        title: '$AsyncScopeExample2 (has scopeKey)',
      ),
    );
  }
}
