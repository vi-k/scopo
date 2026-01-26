import 'package:flutter/material.dart';

import 'counter_scope.dart';

class StreamScopeExample1 extends StatelessWidget {
  static int _num = 0;

  const StreamScopeExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        title: '$StreamScopeExample1 (independent scopes)',
        debugSource: StreamScopeExample1,
        debugName: '${++_num}',
      ),
    );
  }
}
