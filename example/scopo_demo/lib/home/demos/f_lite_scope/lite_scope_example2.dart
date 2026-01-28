import 'package:flutter/material.dart';

import 'counter_scope.dart';

class LiteScopeExample2 extends StatelessWidget {
  static int _num = 0;

  const LiteScopeExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        scopeKey: LiteScopeExample2,
        title: '$LiteScopeExample2 (only one working scope)',
        debugSource: LiteScopeExample2,
        debugName: '${++_num}',
      ),
    );
  }
}
