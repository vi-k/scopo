import 'package:flutter/material.dart';

import 'counter_scope.dart';

class ScopeExample2 extends StatelessWidget {
  static int _num = 0;

  const ScopeExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        scopeKey: ScopeExample2,
        title: '$ScopeExample2 (has scopeKey)',
        debugSource: ScopeExample2,
        debugName: '${++_num}',
      ),
    );
  }
}
