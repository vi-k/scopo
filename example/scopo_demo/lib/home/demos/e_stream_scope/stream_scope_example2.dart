import 'package:flutter/material.dart';

import 'counter_scope.dart';

class StreamScopeExample2 extends StatelessWidget {
  static int _num = 0;

  const StreamScopeExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        scopeKey: StreamScopeExample2,
        title: '$StreamScopeExample2 (only one working scope)',
        debugSource: StreamScopeExample2,
        debugName: '${++_num}',
      ),
    );
  }
}
