import 'package:flutter/material.dart';

import 'counter_scope.dart';

class LiteScopeExample1 extends StatelessWidget {
  static int _num = 0;

  const LiteScopeExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CounterScope(
        title: '$LiteScopeExample1 (independent scope)',
        debugSource: LiteScopeExample1,
        debugName: '${++_num}',
      ),
    );
  }
}
